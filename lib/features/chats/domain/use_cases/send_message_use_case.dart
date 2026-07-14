import 'package:collab_tasks/features/chats/domain/models/message_entity.dart';
import 'package:collab_tasks/features/chats/domain/repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository _repository;

  const SendMessageUseCase(this._repository);

  Future<void> call(String chatId, MessageEntity message) {
    return _repository.sendMessage(chatId, message);
  }
}
