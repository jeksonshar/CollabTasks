import 'dart:async';
import 'dart:convert';

import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/chats/data/remote/chat_remote_data_source.dart';
import 'package:collab_tasks/features/chats/data/remote/models/chat_dto.dart';
import 'package:collab_tasks/features/chats/data/remote/models/group_chat_dto.dart';
import 'package:collab_tasks/features/chats/data/remote/models/message_dto.dart';
import 'package:collab_tasks/features/chats/data/remote/models/ws_typing_dto.dart';
import 'package:collab_tasks/features/chats/data/remote/models/ws_user_status_dto.dart';
import 'package:collab_tasks/features/working_groups/data/local/working_groups_local_data_source.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Тип фабрики, создающей [WebSocketChannel] по URI.
/// Позволяет подменять реальное соединение на заглушку в тестах.
typedef WebSocketChannelFactory = WebSocketChannel Function(Uri uri);

/// Тип провайдера токена: асинхронно возвращает актуальный токен
/// (например, Firebase ID-токен) или `null`, если пользователь не авторизован.
typedef TokenProvider = Future<String?> Function();

/// [ChatRemoteDataSource], работающий поверх кастомного Node.js WebSocket-сервера.
///
/// Соединение устанавливается лениво при первом обращении и переиспользуется
/// до явного вызова [dispose] или критической ошибки сети.
///
/// ### Паттерн Completer для Future-методов
/// Каждый запрос, ожидающий ответа, регистрирует [Completer] в карте
/// [_pendingCompleters], ключом служит тип ожидаемого ответного события.
/// Входящие сообщения разбираются в [_handleIncomingMessage] и завершают
/// соответствующий Completer.
///
/// ### Реактивные потоки сообщений
/// [watchMessages] / [watchGroupMessages] возвращают [Stream] из
/// [StreamController.broadcast]. При первой подписке клиент отправляет
/// `subscribe_topic`, при отмене — `unsubscribe_topic`. Локальный кэш
/// [_messagesCache] обновляется при получении `new_message` / `message_deleted`.
class WebSocketChatRemoteDataSource implements ChatRemoteDataSource {
  final String _baseUrl;

  /// Вызывается непосредственно перед установкой нового WebSocket-соединения,
  /// чтобы получить актуальный токен авторизации.
  final TokenProvider _getTokenProvider;

  final WebSocketChannelFactory _channelFactory;

  WebSocketChatRemoteDataSource({
    required String baseUrl,
    required Future<String?> Function() getTokenProvider,
    WebSocketChannelFactory? channelFactory,
  }) : _baseUrl = baseUrl,
       _getTokenProvider = getTokenProvider,
       _channelFactory = channelFactory ?? _defaultChannelFactory;

  // ---------------------------------------------------------------------------
  // Внутреннее состояние
  // ---------------------------------------------------------------------------

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSubscription;

  /// Ожидающие Completer'ы: ключ — тип ответного события сервера.
  /// Значение — список, т. к. теоретически возможны параллельные запросы
  /// одного типа (например, getChatById с разными chatId).
  final Map<String, List<_PendingRequest<dynamic>>> _pendingCompleters = {};

  /// Кэш сообщений: ключ — chatId или groupId.
  final Map<String, List<MessageDto>> _messagesCache = {};

  /// StreamController'ы для активных подписок на топики.
  final Map<String, StreamController<List<MessageDto>>> _topicControllers = {};

  /// Счётчик активных слушателей на топик (для отслеживания ref-count).
  final Map<String, int> _topicListenerCount = {};

  /// Broadcast-поток событий статуса онлайн/офлайн пользователей.
  final StreamController<WsUserStatusDto> _userStatusController =
      StreamController<WsUserStatusDto>.broadcast();

  /// Broadcast-поток событий набора текста в прямых чатах.
  final StreamController<WsTypingDto> _typingController = StreamController<WsTypingDto>.broadcast();

  // ---------------------------------------------------------------------------
  // Публичные реактивные потоки
  // ---------------------------------------------------------------------------

  /// Поток событий изменения статуса присутствия пользователей.
  /// Подписывайтесь для получения `user_status_changed` от сервера.
  Stream<WsUserStatusDto> get userStatusStream => _userStatusController.stream;

  /// Поток событий набора текста в прямых чатах.
  /// Подписывайтесь для получения `typing` от сервера.
  Stream<WsTypingDto> get typingStream => _typingController.stream;

  // ---------------------------------------------------------------------------
  // Фабрика канала по умолчанию
  // ---------------------------------------------------------------------------

  static WebSocketChannel _defaultChannelFactory(Uri uri) => WebSocketChannel.connect(uri);

  // ---------------------------------------------------------------------------
  // Управление соединением
  // ---------------------------------------------------------------------------

  /// Возвращает существующий или создаёт новый [WebSocketChannel].
  ///
  /// При создании нового канала получает актуальный токен через [_getTokenProvider]
  /// и передаёт его в URL в виде query-параметра `token`.
  Future<WebSocketChannel> _getOrCreateChannel() async {
    if (_channel != null) return _channel!;

    final token = await _getTokenProvider();
    final tokenParam = token != null ? '?token=${Uri.encodeComponent(token)}' : '';
    final uri = Uri.parse('$_baseUrl$tokenParam');
    _channel = _channelFactory(uri);

    _channelSubscription = _channel!.stream.listen(
      _handleIncomingMessage,
      onError: _handleConnectionError,
      onDone: _handleConnectionDone,
      cancelOnError: false,
    );

    return _channel!;
  }

  /// Отправляет JSON-объект через WebSocket.
  Future<void> _send(Map<String, dynamic> payload) async {
    try {
      final channel = await _getOrCreateChannel();
      channel.sink.add(jsonEncode(payload));
    } catch (e, st) {
      debugPrint('[WS] Ошибка отправки: $e\n$st');
    }
  }

  // ---------------------------------------------------------------------------
  // Обработка входящих сообщений
  // ---------------------------------------------------------------------------

  void _handleIncomingMessage(dynamic raw) {
    if (raw is! String) return;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[WS] Не удалось разобрать JSON: $raw');
      return;
    }

    final type = data['type'] as String?;
    if (type == null) {
      debugPrint('[WS] Получено сообщение без поля "type": $data');
      return;
    }

    switch (type) {
      case 'chat_list':
        _resolveFirst<List<ChatDto>>(type, () {
          final rawChats = data['chats'] as List<dynamic>? ?? const [];
          return rawChats
              .whereType<Map<String, dynamic>>()
              .map((m) => ChatDto.fromFirestore(m, m['id'] as String? ?? ''))
              .toList();
        });

      case 'direct_chat_created':
        _resolveFirst<String>(type, () => data['chatId'] as String? ?? '');

      case 'chat_by_id':
        _resolveFirst<ChatDto?>(type, () {
          final raw = data['chat'];
          if (raw == null) return null;
          final m = raw as Map<String, dynamic>;
          return ChatDto.fromFirestore(m, m['id'] as String? ?? '');
        });

      case 'group_chat_by_id':
        _resolveFirst<GroupChatDto?>(type, () {
          final raw = data['chat'];
          if (raw == null) return null;
          final m = raw as Map<String, dynamic>;
          return GroupChatDto.fromFirestore(m, m['id'] as String? ?? '');
        });

      case 'new_message':
      case 'new_group_message':
        _handleNewMessage(data);

      case 'message_deleted':
      case 'group_message_deleted':
        _handleMessageDeleted(data);

      case 'user_status_changed':
        _handleUserStatusChanged(data);

      case 'typing':
        _handleTypingEvent(data);

      case 'error':
        final msg = data['message'] as String? ?? 'Неизвестная ошибка сервера';
        final targetType = data['requestType'] as String?;
        debugPrint('[WS] Ошибка сервера (тип запроса: $targetType): $msg');
        if (targetType != null) {
          _failFirst(targetType, Exception('[WS] $msg'));
        }

      default:
        debugPrint('[WS] Неизвестный тип сообщения: $type');
    }
  }

  // ---------------------------------------------------------------------------
  // Вспомогательные методы для Completer-паттерна
  // ---------------------------------------------------------------------------

  /// Регистрирует ожидающий запрос и возвращает его Future.
  Future<T> _enqueue<T>(String responseType) {
    final request = _PendingRequest<T>();
    _pendingCompleters.putIfAbsent(responseType, () => []).add(request as _PendingRequest<dynamic>);
    return request.future;
  }

  /// Завершает первый ожидающий Completer для [responseType] с вычисленным значением.
  void _resolveFirst<T>(String responseType, T Function() compute) {
    final queue = _pendingCompleters[responseType];
    if (queue == null || queue.isEmpty) return;

    final request = queue.removeAt(0) as _PendingRequest<T>;
    try {
      request.complete(compute());
    } catch (e, st) {
      request.completeError(e, st);
    }
    if (queue.isEmpty) _pendingCompleters.remove(responseType);
  }

  /// Завершает первый ожидающий Completer с ошибкой.
  void _failFirst(String responseType, Object error) {
    final queue = _pendingCompleters[responseType];
    if (queue == null || queue.isEmpty) return;

    queue.removeAt(0).completeError(error);
    if (queue.isEmpty) _pendingCompleters.remove(responseType);
  }

  // ---------------------------------------------------------------------------
  // Обработка событий реального времени
  // ---------------------------------------------------------------------------

  void _handleNewMessage(Map<String, dynamic> data) {
    final rawMsg = data['message'];
    final topicKey = (data['chatId'] ?? data['groupId']) as String?;

    if (rawMsg == null || topicKey == null) {
      debugPrint('[WS] new_message / new_group_message: отсутствуют обязательные поля');
      return;
    }

    final msgMap = rawMsg as Map<String, dynamic>;
    final dto = MessageDto.fromFirestore(msgMap, msgMap['id'] as String? ?? '');

    final current = List<MessageDto>.from(_messagesCache[topicKey] ?? []);
    // Дедупликация по id
    if (!current.any((m) => m.id == dto.id)) {
      current
        ..insert(0, dto)
        // Сортировка: новейшие сначала
        ..sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
      _messagesCache[topicKey] = current;
      _topicControllers[topicKey]?.add(List.unmodifiable(current));
    }
  }

  void _handleMessageDeleted(Map<String, dynamic> data) {
    final topicKey = (data['chatId'] ?? data['groupId']) as String?;
    final messageId = data['messageId'] as String?;

    if (topicKey == null || messageId == null) {
      debugPrint('[WS] message_deleted: отсутствуют обязательные поля');
      return;
    }

    final current = List<MessageDto>.from(_messagesCache[topicKey] ?? []);
    final updated = current.where((m) => m.id != messageId).toList();
    _messagesCache[topicKey] = updated;
    _topicControllers[topicKey]?.add(List.unmodifiable(updated));
  }

  /// Обрабатывает входящее событие `user_status_changed` от сервера.
  /// Публикует [WsUserStatusDto] в [userStatusStream].
  void _handleUserStatusChanged(Map<String, dynamic> data) {
    try {
      final dto = WsUserStatusDto.fromMap(data);
      if (!_userStatusController.isClosed) {
        _userStatusController.add(dto);
      }
      debugPrint('[WS] user_status_changed: userId=${dto.userId} status=${dto.status.name}');
    } catch (e) {
      debugPrint('[WS] Ошибка разбора user_status_changed: $e');
    }
  }

  /// Обрабатывает входящее событие `typing` от сервера.
  /// Публикует [WsTypingDto] в [typingStream].
  void _handleTypingEvent(Map<String, dynamic> data) {
    try {
      final dto = WsTypingDto.fromMap(data);
      if (!_typingController.isClosed) {
        _typingController.add(dto);
      }
      debugPrint('[WS] typing: chatId=${dto.chatId} userId=${dto.userId} isTyping=${dto.isTyping}');
    } catch (e) {
      debugPrint('[WS] Ошибка разбора typing: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Обработка ошибок и закрытия соединения
  // ---------------------------------------------------------------------------

  void _handleConnectionError(Object error, StackTrace st) {
    debugPrint('[WS] Ошибка соединения: $error\n$st');
    _failAllPending(error);
    _resetConnection();
  }

  void _handleConnectionDone() {
    debugPrint('[WS] Соединение закрыто сервером.');
    _failAllPending(const WebSocketConnectionException('Соединение с WebSocket-сервером прервано'));
    _resetConnection();
  }

  void _failAllPending(Object error) {
    for (final queue in _pendingCompleters.values) {
      for (final request in queue) {
        request.completeError(error);
      }
    }
    _pendingCompleters.clear();
  }

  void _resetConnection() {
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel = null;
  }

  // ---------------------------------------------------------------------------
  // Управление топиками (subscribe / unsubscribe)
  // ---------------------------------------------------------------------------

  StreamController<List<MessageDto>> _getOrCreateTopicController(String key) {
    return _topicControllers.putIfAbsent(key, () => StreamController<List<MessageDto>>.broadcast());
  }

  Stream<List<MessageDto>> _watchTopic({required String key, required String topicId}) {
    // Не сохраняем controller в локальную переменную, чтобы анализатор
    // не считал StreamController незакрытым Sink'ом (close_sinks lint).
    // Жизненным циклом controller управляет _topicControllers.
    return _getOrCreateTopicController(key).stream.asBroadcastStream(
      onListen: (_) {
        final count = (_topicListenerCount[key] ?? 0) + 1;
        _topicListenerCount[key] = count;
        if (count == 1) {
          // Первый слушатель — подписываемся на сервере.
          // После subscribe сервер пришлёт историю через new_message,
          // но если чат пуст — ничего не придёт и стрим молчал бы вечно.
          // Поэтому через microtask гарантированно эмитим текущее состояние
          // кэша (даже пустой список), чтобы Bloc перешёл из Loading → Loaded.
          _send({'type': 'subscribe_topic', 'topicId': topicId});
          debugPrint('[WS] Подписка на топик: $topicId');
          Future.microtask(() {
            final cached = _messagesCache[key];
            _topicControllers[key]?.add(List.unmodifiable(cached ?? []));
          });
        } else {
          // Повторный слушатель — отдаём кэш если не пустой
          final cached = _messagesCache[key];
          if (cached != null && cached.isNotEmpty) {
            _topicControllers[key]?.add(List.unmodifiable(cached));
          }
        }
      },
      onCancel: (_) {
        final count = (_topicListenerCount[key] ?? 1) - 1;
        if (count <= 0) {
          _topicListenerCount.remove(key);
          _topicControllers.remove(key)?.close();
          _messagesCache.remove(key);
          // unawaited — fire-and-forget при отписке
          _send({'type': 'unsubscribe_topic', 'topicId': topicId});
          debugPrint('[WS] Отписка от топика: $topicId');
        } else {
          _topicListenerCount[key] = count;
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Реализация ChatRemoteDataSource
  // ---------------------------------------------------------------------------

  @override
  Stream<List<MessageDto>> watchMessages(String chatId) {
    return _watchTopic(key: chatId, topicId: 'chat:$chatId');
  }

  @override
  Future<void> sendMessage(String chatId, MessageDto message) async {
    await _send({
      'type': 'send_message',
      'chatId': chatId,
      'message': {'id': message.id, ...message.toFirestore()},
    });
  }

  @override
  Stream<List<MessageDto>> watchGroupMessages(String groupId) {
    return _watchTopic(key: groupId, topicId: 'group:$groupId');
  }

  @override
  Future<void> sendGroupMessage(String groupId, MessageDto message) async {
    await _send({
      'type': 'send_group_message',
      'groupId': groupId,
      'message': {'id': message.id, ...message.toFirestore()},
    });
  }

  @override
  Future<List<ChatDto>> getChats(String userId) async {
    await _send({'type': 'get_chats', 'userId': userId});
    return _enqueue<List<ChatDto>>('chat_list');
  }

  @override
  Future<String> getOrCreateDirectChat(String targetUserId) async {
    await _send({'type': 'get_or_create_direct_chat', 'targetUserId': targetUserId});
    return _enqueue<String>('direct_chat_created');
  }

  @override
  Future<ChatDto?> getChatById(String chatId) async {
    await _send({'type': 'get_chat_by_id', 'chatId': chatId});
    return _enqueue<ChatDto?>('chat_by_id');
  }

  @override
  Future<GroupChatDto?> getGroupChatById(String chatId) async {
    await _send({'type': 'get_group_chat_by_id', 'chatId': chatId});
    final serverChat = await _enqueue<GroupChatDto?>('group_chat_by_id');
    if (serverChat != null && serverChat.title.isNotEmpty) {
      return serverChat;
    }

    // Fallback на локальную рабочую группу, если на WS сервере еще нет метаданных
    try {
      if (getIt.isRegistered<WorkingGroupsLocalDataSource>()) {
        final localDs = getIt<WorkingGroupsLocalDataSource>();
        final localGroup = await localDs.watchGroup(chatId).first;
        if (localGroup != null) {
          final participants = await localDs.getParticipants(chatId);
          final dto = GroupChatDto(
            id: chatId,
            participantUserIds: participants.map((p) => p.userId).toList(),
            participantEmails: participants.map((p) => p.userId).toList(),
            title: localGroup.title,
            description: localGroup.description,
            updatedAtMillis: localGroup.updatedAt,
          );
          // Сохраняем/синхронизируем метаданные на WS сервер
          unawaited(_send({'type': 'upsert_group_chat', 'chat': dto.toFirestore()}));
          return dto;
        }
      }
    } catch (e) {
      debugPrint('[WS] Ошибка получения локальной метаинформации группы: $e');
    }

    return serverChat;
  }

  @override
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _send({'type': 'delete_message', 'chatId': chatId, 'messageId': messageId});
  }

  // ---------------------------------------------------------------------------
  // Утилиты
  // ---------------------------------------------------------------------------

  /// Уведомляет сервер о статусе набора текста в прямом чате (fire-and-forget).
  ///
  /// Вызывайте с [isTyping] = `true` когда пользователь начинает печатать,
  /// и с [isTyping] = `false` — когда останавливается (или через debounce).
  void sendTyping(String chatId, {required bool isTyping}) {
    _send({'type': 'typing', 'chatId': chatId, 'isTyping': isTyping});
  }

  /// Синхронизирует FCM-токен с сервером (fire-and-forget).
  void syncFcmToken(String token) {
    // unawaited — fire-and-forget
    _send({'type': 'sync_fcm_token', 'token': token});
  }

  /// Удаляет FCM-токен устройства с сервера при выходе из аккаунта (логауте).
  Future<void> removeFcmToken(String token) async {
    await _send({'type': 'remove_fcm_token', 'token': token});
  }

  /// Закрывает WebSocket-соединение и освобождает все ресурсы.
  Future<void> dispose() async {
    _failAllPending(const WebSocketConnectionException('DataSource был уничтожен'));
    for (final controller in _topicControllers.values) {
      await controller.close();
    }
    _topicControllers.clear();
    _topicListenerCount.clear();
    _messagesCache.clear();

    await _userStatusController.close();
    await _typingController.close();

    await _channelSubscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
  }
}

// ---------------------------------------------------------------------------
// Вспомогательные типы
// ---------------------------------------------------------------------------

/// Обёртка над [Completer], хранящая ожидающий запрос.
class _PendingRequest<T> {
  final Completer<T> _completer = Completer<T>();

  Future<T> get future => _completer.future;

  void complete(T value) {
    if (!_completer.isCompleted) _completer.complete(value);
  }

  void completeError(Object error, [StackTrace? st]) {
    if (!_completer.isCompleted) _completer.completeError(error, st);
  }
}

/// Кастомное исключение для ошибок WebSocket-соединения.
class WebSocketConnectionException implements Exception {
  final String message;

  const WebSocketConnectionException(this.message);

  @override
  String toString() => 'WebSocketConnectionException: $message';
}
