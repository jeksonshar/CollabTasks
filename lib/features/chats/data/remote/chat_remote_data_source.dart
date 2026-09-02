import 'package:collab_tasks/core/paging/chats_paging_constants.dart';
import 'package:collab_tasks/features/chats/data/remote/models/chat_dto.dart';
import 'package:collab_tasks/features/chats/data/remote/models/group_chat_dto.dart';
import 'package:collab_tasks/features/chats/data/remote/models/message_dto.dart';

abstract class ChatRemoteDataSource {
  Stream<List<MessageDto>> watchMessages(String chatId);

  Future<void> sendMessage(String chatId, MessageDto message);

  Stream<List<MessageDto>> watchGroupMessages(String groupId);

  Future<void> sendGroupMessage(String groupId, MessageDto message);

  Future<List<ChatDto>> getChats(String userId);

  Future<String> getOrCreateDirectChat(String targetUserId);

  Future<ChatDto?> getChatById(String chatId);

  Future<GroupChatDto?> getGroupChatById(String chatId);

  Future<void> deleteMessage(String chatId, String messageId);

  Future<bool> loadMoreMessages(
    String chatId, {
    required int beforeCreatedAtMillis,
    required String beforeId,
    int limit = limitOnPage,
  });

  Future<bool> loadMoreGroupMessages(
    String groupId, {
    required int beforeCreatedAtMillis,
    required String beforeId,
    int limit = limitOnPage,
  });
}
