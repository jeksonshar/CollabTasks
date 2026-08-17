import 'package:collab_tasks/features/chats/domain/models/chat_entity.dart';
import 'package:collab_tasks/features/chats/domain/models/group_chat_entity.dart';
import 'package:collab_tasks/features/chats/domain/models/message_entity.dart';
import 'package:collab_tasks/features/chats/domain/models/typing_status_entity.dart';
import 'package:collab_tasks/features/chats/domain/models/user_status_entity.dart';

abstract class ChatRepository {
  Stream<List<MessageEntity>> watchMessages(String chatId);

  Future<void> sendMessage(String chatId, MessageEntity message);

  Stream<List<MessageEntity>> watchGroupMessages(String groupId);

  Future<void> sendGroupMessage({
    required String groupId,
    required String content,
    required String senderId,
  });

  Future<List<ChatEntity>> getChats();

  Future<String> getOrCreateDirectChat(String targetUserId);

  Future<ChatEntity?> getChatById(String chatId);

  Future<GroupChatEntity?> getGroupChatById(String chatId);

  Future<void> deleteMessage(String chatId, String messageId);

  Stream<UserStatusEntity> watchUserStatus(String userId);

  Stream<TypingStatusEntity> watchTypingStatus(String chatId);

  Future<void> sendTypingStatus(String chatId, bool isTyping);
}
