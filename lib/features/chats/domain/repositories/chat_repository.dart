import 'package:collab_tasks/features/chats/domain/models/chat_entity.dart';
import 'package:collab_tasks/features/chats/domain/models/message_entity.dart';

abstract class ChatRepository {
  Stream<List<MessageEntity>> watchMessages(String chatId);

  Future<void> sendMessage(String chatId, MessageEntity message);

  Future<List<ChatEntity>> getChats();

  Future<String> getOrCreateDirectChat(String targetUserId);
}
