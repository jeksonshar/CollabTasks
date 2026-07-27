import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collab_tasks/features/chats/ui/screens/chat_screen.dart';
import 'package:collab_tasks/features/chats/ui/screens/group_chat_screen.dart';
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
  String? _pendingDirectChatId;
  String? _pendingGroupChatId;

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
          if (_pendingGroupChatId != null) {
            _handleGroupChatNotificationTap(payload);
            _pendingGroupChatId = null;
          } else if (_pendingDirectChatId != null) {
            _handleDirectChatNotificationTap(payload);
            _pendingDirectChatId = null;
          }
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
      final directChatId = message.data['chatId'];
      final groupChatId = message.data['groupId'];
      debugPrint('=== [FCM] 4. directChatId = $directChatId, groupChatId = $groupChatId');
      if (directChatId != null) {
        _handleDirectChatNotificationTap(directChatId);
      } else if (groupChatId != null) {
        _handleGroupChatNotificationTap(groupChatId);
      }
    });

    // 5. ОБРАБОТКА ХОЛОДНОГО СТАРТА (когда приложение было выгружено из памяти)
    final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('=== [FCM] Приложение запущено из убитого состояния по клику на пуш ===');
      final directChatId = initialMessage.data['chatId'];
      final groupChatId = initialMessage.data['groupId'];
      if (directChatId != null) {
        // Запоминаем ID, так как контекст навигации на этом этапе ещё НЕ готов!
        _pendingDirectChatId = directChatId;
      } else if (groupChatId != null) {
        _pendingGroupChatId = groupChatId;
      }
    }

    _isInitialized = true;
  }

  /// Метод, который вызовется в главном экране приложения (в HomeScreen) после сборки UI
  void checkPendingNotification() {
    debugPrint('checkPendingNotification() _pendingChatId = $_pendingDirectChatId');
    if (_pendingDirectChatId != null) {
      _handleDirectChatNotificationTap(_pendingDirectChatId!);
      _pendingDirectChatId = null;
    }
    if (_pendingGroupChatId != null) {
      _handleGroupChatNotificationTap(_pendingGroupChatId!);
      _pendingGroupChatId = null;
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
    final directChatId = message.data['chatId'];
    final groupChatId = message.data['groupId'];

    debugPrint('=== [FCM] _showLocalBanner() directChatId = $directChatId, groupId = $groupChatId');

    if (directChatId != null) {
      _pendingDirectChatId = directChatId;
    } else if (groupChatId != null) {
      _pendingGroupChatId = groupChatId;
    }

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
        payload: directChatId ?? groupChatId,
      );
    }
  }

  // Навигация или обработка клика по пушу
  void _handleDirectChatNotificationTap(String directChatId) {
    debugPrint('=== [FCM] Переход в экран direct чата: $directChatId ===');

    // Проверяем, авторизован ли пользователь во всей системе
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('=== [FCM] Отмена навигации direct чата: пользователь не авторизован! ===');
      return; // Никуда не переходим, просто игнорируем клик
    }

    final context = globalNavigatorKey.currentContext;
    if (context == null) {
      _pendingDirectChatId = directChatId;
      debugPrint('=== [FCM] Ошибка навигации direct чата: navigatorKey.currentContext is null ===');
      return;
    }

    // Переходим на экран директ чата
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ChatScreen(chatId: directChatId)));
  }

  void _handleGroupChatNotificationTap(String groupChatId) {
    debugPrint('=== [FCM] Переход в экран группового чата: $groupChatId ===');

    // Проверяем, авторизован ли пользователь во всей системе
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('=== [FCM] Отмена навигации группового чата: пользователь не авторизован! ===');
      return; // Никуда не переходим, просто игнорируем клик
    }

    final context = globalNavigatorKey.currentContext;
    if (context == null) {
      _pendingGroupChatId = groupChatId;
      debugPrint(
        '=== [FCM] Ошибка навигации группового чата: navigatorKey.currentContext is null ===',
      );
      return;
    }

    // Переходим на экран группового чата
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => GroupChatScreen(groupId: groupChatId)));
  }
}
