import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:collab_tasks/core/paging/chats_paging_constants.dart';
import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/chats/data/remote/chat_remote_data_source.dart';
import 'package:collab_tasks/features/chats/data/remote/models/chat_dto.dart';
import 'package:collab_tasks/features/chats/data/remote/models/group_chat_dto.dart';
import 'package:collab_tasks/features/chats/data/remote/models/message_dto.dart';
import 'package:collab_tasks/features/chats/data/remote/models/ws_typing_dto.dart';
import 'package:collab_tasks/features/chats/data/remote/models/ws_user_status_dto.dart';
import 'package:collab_tasks/features/working_groups/data/local/working_groups_local_data_source.dart';
import 'package:flutter/widgets.dart';
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
/// ### Автоматическое переподключение
/// При разрыве соединения (блокировка экрана, Render idle timeout, потеря сети)
/// класс автоматически переподключается с экспоненциальным backoff и
/// переподписывается на все активные топики через `_activeTopicIds`.
///
/// При возврате приложения из фона ([AppLifecycleState.resumed]) проверяется
/// состояние канала и, если он мёртв, немедленно запускается переподключение.
///
/// ### Паттерн Completer для Future-методов
/// Каждый запрос, ожидающий ответа, регистрирует [Completer] в карте
/// [_pendingCompleters], ключом служит тип ожидаемого ответного события.
///
/// ### Реактивные потоки сообщений
/// [watchMessages] / [watchGroupMessages] возвращают [Stream] из
/// [StreamController.broadcast]. При первой подписке клиент отправляет
/// `subscribe_topic`, при отмене — `unsubscribe_topic`. Локальный кэш
/// [_messagesCache] обновляется при получении `new_message` / `message_deleted`.
class WebSocketChatRemoteDataSource with WidgetsBindingObserver implements ChatRemoteDataSource {
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
       _channelFactory = channelFactory ?? _defaultChannelFactory {
    // Регистрируемся как observer жизненного цикла приложения.
    // При переходе в resumed — проверяем/восстанавливаем соединение.
    WidgetsBinding.instance.addObserver(this);
  }

  // ---------------------------------------------------------------------------
  // Внутреннее состояние
  // ---------------------------------------------------------------------------

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSubscription;

  /// Флаг уничтожения объекта — блокирует все переподключения после [dispose].
  bool _isDisposed = false;

  /// Ожидающие Completer'ы: ключ — тип ответного события сервера.
  /// Значение — список, т. к. теоретически возможны параллельные запросы
  /// одного типа (например, getChatById с разными chatId).
  final Map<String, List<_PendingRequest<dynamic>>> _pendingCompleters = {};

  /// Кэш сообщений: ключ — chatId или groupId.
  final Map<String, List<MessageDto>> _messagesCache = {};

  /// Кэш флага наличия более старых сообщений: ключ — chatId или groupId.
  final Map<String, bool> _hasMoreCache = {};

  /// StreamController'ы для активных подписок на топики.
  final Map<String, StreamController<List<MessageDto>>> _topicControllers = {};

  /// Счётчик активных слушателей на топик (для отслеживания ref-count).
  final Map<String, int> _topicListenerCount = {};

  /// Активные серверные подписки: key (chatId/groupId) → topicId ('chat:xxx' / 'group:xxx').
  ///
  /// Заполняется при первой подписке слушателя на топик, очищается при уходе
  /// последнего слушателя. Используется при переподключении: после создания
  /// нового канала все записанные топики переподписываются на сервере,
  /// чтобы `new_message` / `new_group_message` вновь доставлялись этому клиенту.
  final Map<String, String> _activeTopicIds = {};

  /// Broadcast-поток событий статуса онлайн/офлайн пользователей.
  final StreamController<WsUserStatusDto> _userStatusController =
      StreamController<WsUserStatusDto>.broadcast();

  /// Broadcast-поток событий набора текста в прямых чатах.
  final StreamController<WsTypingDto> _typingController = StreamController<WsTypingDto>.broadcast();

  // ---------------------------------------------------------------------------
  // Переподключение (reconnect + exponential backoff)
  // ---------------------------------------------------------------------------

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  /// Максимальная задержка между попытками переподключения (секунды).
  static const int _maxReconnectDelaySec = 30;

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

      case 'messages_history':
      case 'group_messages_history':
        _handleMessagesHistory(data);

      case 'messages_page':
        _handleMessagesPage(data);

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

  /// Отменяет **все** ожидающие Completers указанного типа.
  ///
  /// Вызывать перед регистрацией нового запроса того же типа, чтобы
  /// не накапливать «мёртвые» [Completer]'ы из предыдущих сессий.
  /// DataSource — синглтон, поэтому без явной очистки устаревший
  /// Completer остаётся в очереди и «съедает» следующий ответ сервера.
  void _clearPendingForType(String responseType) {
    final queue = _pendingCompleters.remove(responseType);
    if (queue == null) return;
    const error = WebSocketConnectionException('Запрос отменён: начат новый запрос того же типа');
    for (final request in queue) {
      request.completeError(error);
    }
    debugPrint(
      '[WS] Очищены устаревшие Completer\'ы для типа: $responseType (${queue.length} шт.)',
    );
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
    final existingIndex = current.indexWhere((m) => m.id == dto.id);
    if (existingIndex >= 0) {
      current[existingIndex] = dto;
    } else {
      current.insert(0, dto);
    }

    // Сортировка: новейшие сначала, при совпадении timestamp — по id (стабильный порядок)
    current.sort((a, b) {
      final cmp = b.createdAtMillis.compareTo(a.createdAtMillis);
      if (cmp != 0) return cmp;
      return b.id.compareTo(a.id);
    });

    _messagesCache[topicKey] = current;
    _topicControllers[topicKey]?.add(List.unmodifiable(current));
  }

  /// Обрабатывает входящее событие `messages_history` / `group_messages_history`.
  /// Атомарно заполняет кэш всей историей за один раз, предотвращая дёрганье UI.
  void _handleMessagesHistory(Map<String, dynamic> data) {
    final rawMessages = data['messages'] as List<dynamic>?;
    final topicKey = (data['chatId'] ?? data['groupId']) as String?;
    final hasMore = data['hasMore'] as bool? ?? false;

    if (rawMessages == null || topicKey == null) {
      debugPrint('[WS] messages_history / group_messages_history: отсутствуют обязательные поля');
      return;
    }

    _hasMoreCache[topicKey] = hasMore;

    final parsedMessages = <MessageDto>[];
    for (final raw in rawMessages) {
      if (raw is Map<String, dynamic>) {
        parsedMessages.add(MessageDto.fromFirestore(raw, raw['id'] as String? ?? ''));
      }
    }

    // Сортировка: новейшие сначала, при совпадении timestamp — по id
    parsedMessages.sort((a, b) {
      final cmp = b.createdAtMillis.compareTo(a.createdAtMillis);
      if (cmp != 0) return cmp;
      return b.id.compareTo(a.id);
    });

    _messagesCache[topicKey] = parsedMessages;
    _topicControllers[topicKey]?.add(List.unmodifiable(parsedMessages));
    debugPrint(
      '[WS] Получена история сообщений для топика $topicKey: ${parsedMessages.length} шт., hasMore: $hasMore',
    );
  }

  /// Обрабатывает входящую страницу старых сообщений `messages_page` при пагинации.
  void _handleMessagesPage(Map<String, dynamic> data) {
    final topicId = data['topicId'] as String? ?? '';
    final topicKey = topicId.startsWith('chat:')
        ? topicId.substring(5)
        : (topicId.startsWith('group:') ? topicId.substring(6) : topicId);

    final rawMessages = data['messages'] as List<dynamic>? ?? [];
    final hasMore = data['hasMore'] as bool? ?? false;
    _hasMoreCache[topicKey] = hasMore;

    final parsedMessages = <MessageDto>[];
    for (final raw in rawMessages) {
      if (raw is Map<String, dynamic>) {
        parsedMessages.add(MessageDto.fromFirestore(raw, raw['id'] as String? ?? ''));
      }
    }

    final current = List<MessageDto>.from(_messagesCache[topicKey] ?? []);
    final existingIds = current.map((m) => m.id).toSet();
    for (final msg in parsedMessages) {
      if (!existingIds.contains(msg.id)) {
        current.add(msg);
      }
    }

    // Сортировка: новейшие сначала, при совпадении timestamp — по id
    current.sort((a, b) {
      final cmp = b.createdAtMillis.compareTo(a.createdAtMillis);
      if (cmp != 0) return cmp;
      return b.id.compareTo(a.id);
    });

    _messagesCache[topicKey] = current;
    _topicControllers[topicKey]?.add(List.unmodifiable(current));
    debugPrint(
      '[WS] Подгружена страница сообщений для топика $topicKey: ${parsedMessages.length} шт., всего в кэше: ${current.length}, hasMore: $hasMore',
    );

    _resolveFirst<bool>('messages_page', () => hasMore);
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
    if (!_isDisposed && _activeTopicIds.isNotEmpty) {
      _scheduleReconnect();
    }
  }

  void _handleConnectionDone() {
    debugPrint('[WS] Соединение закрыто сервером.');
    _failAllPending(const WebSocketConnectionException('Соединение с WebSocket-сервером прервано'));
    _resetConnection();
    // Если есть активные топики — переподключаемся автоматически.
    if (!_isDisposed && _activeTopicIds.isNotEmpty) {
      _scheduleReconnect();
    }
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
  // Автоматическое переподключение (reconnect + exponential backoff)
  // ---------------------------------------------------------------------------

  /// Планирует следующую попытку переподключения с экспоненциальным backoff.
  ///
  /// Задержка: 1с → 2с → 4с → 8с → 16с → 30с (далее не растёт).
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_isDisposed) return;

    final delaySec = min(_maxReconnectDelaySec, pow(2, _reconnectAttempts).toInt());
    _reconnectAttempts++;

    debugPrint('[WS] Переподключение через $delaySecс (попытка #$_reconnectAttempts)...');

    _reconnectTimer = Timer(Duration(seconds: delaySec), _reconnect);
  }

  /// Выполняет одну попытку переподключения.
  ///
  /// При успехе:
  /// - создаёт новый WS-канал
  /// - переподписывается на все топики из [_activeTopicIds]
  /// - эмитит текущий кэш в каждый [StreamController], чтобы UI не мигал
  ///
  /// При ошибке — планирует следующую попытку через [_scheduleReconnect].
  Future<void> _reconnect() async {
    if (_isDisposed) return;

    // Нет активных топиков — переподключаться незачем.
    if (_activeTopicIds.isEmpty) {
      _reconnectAttempts = 0;
      return;
    }

    try {
      debugPrint(
        '[WS] Попытка переподключения #$_reconnectAttempts '
        '(активных топиков: ${_activeTopicIds.length})',
      );

      final channel = await _getOrCreateChannel();

      // Переподписываемся на все активные топики одним проходом.
      // Берём snapshot, чтобы не итерировать изменяемую карту.
      final snapshot = Map<String, String>.from(_activeTopicIds);
      for (final entry in snapshot.entries) {
        channel.sink.add(jsonEncode({'type': 'subscribe_topic', 'topicId': entry.value}));
        // Сразу эмитим кэш, чтобы UI показал уже загруженные сообщения
        // пока не придут новые события от сервера.
        final cached = _messagesCache[entry.key];
        _topicControllers[entry.key]?.add(List.unmodifiable(cached ?? const []));
        debugPrint('[WS] Переподписка на топик: ${entry.value}');
      }

      _reconnectAttempts = 0;
      debugPrint('[WS] ✅ Переподключение выполнено успешно.');
    } catch (e) {
      debugPrint('[WS] Ошибка переподключения: $e');
      _resetConnection();
      if (!_isDisposed) _scheduleReconnect();
    }
  }

  // ---------------------------------------------------------------------------
  // AppLifecycleObserver — восстановление при выходе из фона
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  /// Вызывается когда приложение возвращается на передний план.
  ///
  /// Если канал мёртв (был разорван пока экран был заблокирован) и есть
  /// активные топики — немедленно сбрасывает backoff и запускает переподключение.
  void _onAppResumed() {
    if (_isDisposed) return;
    debugPrint('[WS] App resumed — проверка состояния WS-соединения...');

    if (_channel == null && _activeTopicIds.isNotEmpty) {
      debugPrint('[WS] Канал мёртв — немедленное переподключение.');
      // Сбрасываем задержку: пользователь ждёт, нужно быстро.
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      _scheduleReconnect();
    } else if (_channel != null) {
      debugPrint('[WS] Канал существует, соединение актуально.');
    }
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
          // Первый слушатель — регистрируем топик для reconnect
          // и подписываемся на сервере.
          _activeTopicIds[key] = topicId;
          _send({'type': 'subscribe_topic', 'topicId': topicId});
          debugPrint('[WS] Подписка на топик: $topicId');

          // Если в кэше уже есть данные от предыдущего открытия, сразу отдаём их
          final cached = _messagesCache[key];
          if (cached != null) {
            Future.microtask(() {
              _topicControllers[key]?.add(List.unmodifiable(cached));
            });
          }
        } else {
          // Повторный слушатель — отдаём кэш если он инициализирован
          final cached = _messagesCache[key];
          if (cached != null) {
            _topicControllers[key]?.add(List.unmodifiable(cached));
          }
        }
      },
      onCancel: (_) {
        final count = (_topicListenerCount[key] ?? 1) - 1;
        if (count <= 0) {
          _topicListenerCount.remove(key);
          // Снимаем регистрацию топика — при переподключении подписываться не нужно.
          _activeTopicIds.remove(key);
          _topicControllers.remove(key)?.close();
          _messagesCache.remove(key);
          // unawaited — fire-and-forget при отписке.
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
    _clearPendingForType('chat_list');
    final future = _enqueue<List<ChatDto>>('chat_list');
    await _send({'type': 'get_chats', 'userId': userId});
    return future.timeout(
      const Duration(seconds: 120),
      onTimeout: () =>
          throw const WebSocketConnectionException('Превышено время ожидания списка чатов (120 с)'),
    );
  }

  @override
  Future<String> getOrCreateDirectChat(String targetUserId) async {
    // 1. Очищаем устаревшие Completers от прошлых сессий.
    //    DataSource — синглтон: без очистки старый Completer «съедает» ответ
    //    нового запроса и новый зависает навсегда.
    _clearPendingForType('direct_chat_created');

    // 2. Регистрируем Completer ДО отправки сообщения, чтобы не потерять
    //    ответ, который может прийти немедленно после reconnect.
    final future = _enqueue<String>('direct_chat_created');

    await _send({'type': 'get_or_create_direct_chat', 'targetUserId': targetUserId});

    // 3. Таймаут 120 с: гарантирует завершение Future при любом исходе.
    //    Render free-tier cold start занимает до 60 с — берём с запасом.
    return future.timeout(
      const Duration(seconds: 120),
      onTimeout: () => throw const WebSocketConnectionException(
        'Превышено время ожидания ответа от сервера (120 с)',
      ),
    );
  }

  @override
  Future<ChatDto?> getChatById(String chatId) async {
    final future = _enqueue<ChatDto?>('chat_by_id');
    await _send({'type': 'get_chat_by_id', 'chatId': chatId});
    return future.timeout(
      const Duration(seconds: 120),
      onTimeout: () =>
          throw const WebSocketConnectionException('Превышено время ожидания данных чата (120 с)'),
    );
  }

  @override
  Future<GroupChatDto?> getGroupChatById(String chatId) async {
    final future = _enqueue<GroupChatDto?>('group_chat_by_id');
    await _send({'type': 'get_group_chat_by_id', 'chatId': chatId});
    final serverChat = await future.timeout(
      const Duration(seconds: 120),
      onTimeout: () => throw const WebSocketConnectionException(
        'Превышено время ожидания данных группового чата (120 с)',
      ),
    );
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

  @override
  Future<bool> loadMoreMessages(
    String chatId, {
    required int beforeCreatedAtMillis,
    required String beforeId,
    int limit = limitOnPage,
  }) async {
    final future = _enqueue<bool>('messages_page');
    await _send({
      'type': 'load_more_messages',
      'topicId': 'chat:$chatId',
      'beforeCreatedAtMillis': beforeCreatedAtMillis,
      'beforeId': beforeId,
      'limit': limit,
    });
    return future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _failFirst('messages_page', TimeoutException('[WS] Таймаут loadMoreMessages ($chatId)'));
        return false;
      },
    );
  }

  @override
  Future<bool> loadMoreGroupMessages(
    String groupId, {
    required int beforeCreatedAtMillis,
    required String beforeId,
    int limit = limitOnPage,
  }) async {
    final future = _enqueue<bool>('messages_page');
    await _send({
      'type': 'load_more_messages',
      'topicId': 'group:$groupId',
      'beforeCreatedAtMillis': beforeCreatedAtMillis,
      'beforeId': beforeId,
      'limit': limit,
    });
    return future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _failFirst(
          'messages_page',
          TimeoutException('[WS] Таймаут loadMoreGroupMessages ($groupId)'),
        );
        return false;
      },
    );
  }

  /// Проверяет, есть ли ещё более старые сообщения на сервере для данного топика.
  bool hasMoreMessages(String topicKey) => _hasMoreCache[topicKey] ?? true;

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
    _isDisposed = true;

    // Снимаем observer жизненного цикла.
    WidgetsBinding.instance.removeObserver(this);

    // Отменяем запланированное переподключение.
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _failAllPending(const WebSocketConnectionException('DataSource был уничтожен'));

    for (final controller in _topicControllers.values) {
      await controller.close();
    }
    _topicControllers.clear();
    _topicListenerCount.clear();
    _activeTopicIds.clear();
    _messagesCache.clear();
    _hasMoreCache.clear();

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
