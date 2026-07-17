import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collab_tasks/features/chats/ui/screens/chat_screen.dart';
import 'package:collab_tasks/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ChatNotificationService {
  ChatNotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  String? _pendingChatId;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Запрашиваем разрешения у операционной системы (критично для iOS и Android 13+)
    final NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('=== [FCM] Разрешение на пуши получено ===');
    }

    // 2. Инициализируем локальные уведомления (нужны для вывода баннера, когда приложение ОТКРЫТО)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null) {
          _handleNotificationTap(payload);
        }
      },
    );

    // Создаем канал высокой важности для Android (без него в Foreground баннер не всплывет)
    // Безопасная проверка платформы без использования dart:io
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'chats_messages_channel', // ID совпадает с Cloud Functions
        'Сообщения чата',
        description: 'Уведомления о новых сообщениях в диалогах',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // 3. Слушаем пуши в Foreground (когда приложение ОТКРЫТО прямо сейчас)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('=== [FCM] Пуш прилетел в Foreground ===');
      _showLocalBanner(message);
    });

    // 4. Слушаем клик по пушу, когда приложение было свернуто (в ФОНЕ)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('=== [FCM] Приложение открыто по клику из фона ===');
      final chatId = message.data['chatId'];
      if (chatId != null) {
        _handleNotificationTap(chatId);
      }
    });

    _isInitialized = true;
  }

  /// Метод, который вызовется в главном экране приложения (в HomeScreen) после сборки UI
  void checkPendingNotification() {
    if (_pendingChatId != null) {
      _handleNotificationTap(_pendingChatId!);
      _pendingChatId = null;
    }
  }

  /// Метод для синхронизации токена
  Future<void> syncDeviceToken({required String userId, required String userEmail}) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;

      final normalizedEmail = userEmail.trim().toLowerCase();
      final userDocRef = _firestore.collection('users').doc(userId);

      // 1. Записываем email в корневой документ пользователя (не затирая другие поля)
      await userDocRef.set({
        'email': normalizedEmail,
        'updatedAtMillis': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));

      // 2. Сохраняем FCM-токен в подколлекцию
      await userDocRef
          .collection('tokens')
          .doc(token) // Избегаем дубликатов
          .set({
            'token': token,
            'createdAt': FieldValue.serverTimestamp(),
            'devicePlatform': defaultTargetPlatform.name.toLowerCase(),
          });

      debugPrint('=== [FCM] Токен устройства синхронизирован для пользователя: $userId ===');
    } catch (e) {
      debugPrint('=== [FCM] Ошибка сохранения токена в Firestore: $e ===');
    }
  }

  /// Метод для удаления токена при логауте
  Future<void> removeDeviceToken(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;

      await _firestore.collection('users').doc(userId).collection('tokens').doc(token).delete();

      debugPrint('=== [FCM] Токен устройства успешно удален при выходе ===');
    } catch (e) {
      debugPrint('=== [FCM] Ошибка удаления токена: $e ===');
    }
  }

  // Формирование нативного всплывающего баннера вручную для Foreground режима
  Future<void> _showLocalBanner(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;
    final chatId = message.data['chatId'];

    if (notification != null) {
      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'chats_messages_channel',
            'Сообщения чата',
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: chatId,
      );
    }
  }

  // Навигация или обработка клика по пушу
  void _handleNotificationTap(String chatId) {
    debugPrint('=== [FCM] Переход в экран чата: $chatId ===');

    // Проверяем, авторизован ли пользователь во всей системе
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('=== [FCM] Отмена навигации: пользователь не авторизован! ===');
      return; // Никуда не переходим, просто игнорируем клик
    }

    final context = globalNavigatorKey.currentContext;
    if (context == null) {
      _pendingChatId = chatId;
      // debugPrint('=== [FCM] Ошибка навигации: navigatorKey.currentContext is null ===');
      return;
    }

    // Переходим на экран чата
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatScreen(chatId: chatId)));
  }
}
