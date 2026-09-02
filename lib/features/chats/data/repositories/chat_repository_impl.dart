import 'package:collab_tasks/core/paging/chats_paging_constants.dart';
import 'package:collab_tasks/features/chats/data/mappers/chat_ws_mappers.dart';
import 'package:collab_tasks/features/chats/data/remote/chat_remote_data_source.dart';
import 'package:collab_tasks/features/chats/data/remote/models/message_dto.dart';
import 'package:collab_tasks/features/chats/data/remote/web_socket_chat_remote_data_source.dart';
import 'package:collab_tasks/features/chats/domain/models/chat_entity.dart';
import 'package:collab_tasks/features/chats/domain/models/group_chat_entity.dart';
import 'package:collab_tasks/features/chats/domain/models/message_entity.dart';
import 'package:collab_tasks/features/chats/domain/models/typing_status_entity.dart';
import 'package:collab_tasks/features/chats/domain/models/user_status_entity.dart';
import 'package:collab_tasks/features/chats/domain/repositories/chat_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  /// Конкретная реализация WebSocket DataSource для real-time функций.
  /// `null` при использовании Firebase-backend — методы возвращают пустые потоки.
  final WebSocketChatRemoteDataSource? _wsDataSource;

  const ChatRepositoryImpl({
    required ChatRemoteDataSource remoteDataSource,
    WebSocketChatRemoteDataSource? wsDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _wsDataSource = wsDataSource;

  @override
  Stream<List<MessageEntity>> watchMessages(String chatId) {
    return _remoteDataSource
        .watchMessages(chatId)
        .map((dtos) => dtos.map((dto) => dto.toDomain()).toList());
  }

  @override
  Future<void> sendMessage(String chatId, MessageEntity message) {
    final messageDto = MessageDto(
      id: message.id,
      senderId: message.senderId,
      senderName: message.senderName,
      text: message.text,
      createdAtMillis: message.createdAtMillis,
    );
    return _remoteDataSource.sendMessage(chatId, messageDto);
  }

  @override
  Stream<List<MessageEntity>> watchGroupMessages(String groupId) {
    return _remoteDataSource
        .watchGroupMessages(groupId)
        .map((dtos) => dtos.map((dto) => dto.toDomain()).toList());
  }

  @override
  Future<void> sendGroupMessage({
    required String groupId,
    required String content,
    required String senderId,
  }) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final senderName = currentUser?.displayName?.trim().isNotEmpty == true
        ? currentUser!.displayName!.trim()
        : currentUser?.email ?? senderId;

    final messageDto = MessageDto(
      id: const Uuid().v4(),
      senderId: senderId,
      senderName: senderName,
      text: content,
      createdAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
    return _remoteDataSource.sendGroupMessage(groupId, messageDto);
  }

  @override
  Future<List<ChatEntity>> getChats() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const [];
    }
    final dtos = await _remoteDataSource.getChats(userId);
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<String> getOrCreateDirectChat(String targetUserId) {
    return _remoteDataSource.getOrCreateDirectChat(targetUserId);
  }

  @override
  Future<ChatEntity?> getChatById(String chatId) async {
    final dto = await _remoteDataSource.getChatById(chatId);
    return dto?.toDomain();
  }

  @override
  Future<GroupChatEntity?> getGroupChatById(String chatId) async {
    final dto = await _remoteDataSource.getGroupChatById(chatId);
    return dto?.toDomain();
  }

  @override
  Future<void> deleteMessage(String chatId, String messageId) {
    return _remoteDataSource.deleteMessage(chatId, messageId);
  }

  @override
  Future<bool> loadMoreMessages(
    String chatId, {
    required int beforeCreatedAtMillis,
    required String beforeId,
    int limit = limitOnPage,
  }) {
    return _remoteDataSource.loadMoreMessages(
      chatId,
      beforeCreatedAtMillis: beforeCreatedAtMillis,
      beforeId: beforeId,
      limit: limit,
    );
  }

  @override
  Future<bool> loadMoreGroupMessages(
    String groupId, {
    required int beforeCreatedAtMillis,
    required String beforeId,
    int limit = limitOnPage,
  }) {
    return _remoteDataSource.loadMoreGroupMessages(
      groupId,
      beforeCreatedAtMillis: beforeCreatedAtMillis,
      beforeId: beforeId,
      limit: limit,
    );
  }

  // ---------------------------------------------------------------------------
  // Real-time: User Status
  // ---------------------------------------------------------------------------

  /// Возвращает поток событий изменения статуса присутствия для [userId].
  ///
  /// Фильтрует общий `userStatusStream` DataSource'а по нормализованному `userId`
  /// и преобразует каждый [WsUserStatusDto] в [UserStatusEntity] через маппер.
  ///
  /// При Firebase-backend (когда [_wsDataSource] == `null`) возвращает
  /// [Stream.empty()] — подключение к Firebase Presence реализуется отдельно.
  @override
  Stream<UserStatusEntity> watchUserStatus(String userId) {
    final ws = _wsDataSource;
    if (ws == null) return const Stream.empty();

    final normalizedId = userId.trim().toLowerCase();
    return ws.userStatusStream
        .where((dto) => dto.userId == normalizedId)
        .map(wsUserStatusDtoToEntity);
  }

  // ---------------------------------------------------------------------------
  // Real-time: Typing Status
  // ---------------------------------------------------------------------------

  /// Возвращает поток событий набора текста для конкретного [chatId].
  ///
  /// Фильтрует общий `typingStream` DataSource'а по `chatId` и преобразует
  /// каждый [WsTypingDto] в [TypingStatusEntity] через маппер.
  ///
  /// При Firebase-backend (когда [_wsDataSource] == `null`) возвращает
  /// [Stream.empty()].
  @override
  Stream<TypingStatusEntity> watchTypingStatus(String chatId) {
    final ws = _wsDataSource;
    if (ws == null) return const Stream.empty();

    return ws.typingStream.where((dto) => dto.chatId == chatId).map(wsTypingDtoToEntity);
  }

  /// Уведомляет сервер о статусе набора текста в прямом чате.
  ///
  /// При Firebase-backend (когда [_wsDataSource] == `null`) — no-op.
  @override
  Future<void> sendTypingStatus(String chatId, bool isTyping) async {
    _wsDataSource?.sendTyping(chatId, isTyping: isTyping);
  }
}
