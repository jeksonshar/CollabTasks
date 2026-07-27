import 'package:collab_tasks/features/chats/data/remote/chat_remote_data_source.dart';
import 'package:collab_tasks/features/chats/data/remote/models/message_dto.dart';
import 'package:collab_tasks/features/chats/domain/models/chat_entity.dart';
import 'package:collab_tasks/features/chats/domain/models/group_chat_entity.dart';
import 'package:collab_tasks/features/chats/domain/models/message_entity.dart';
import 'package:collab_tasks/features/chats/domain/repositories/chat_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  const ChatRepositoryImpl({required ChatRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

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
    // Передаем запрос в RemoteDataSource
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
}
