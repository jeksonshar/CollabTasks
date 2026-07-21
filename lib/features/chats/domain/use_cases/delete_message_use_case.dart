import 'package:collab_tasks/features/chats/domain/repositories/chat_repository.dart';

class DeleteMessageUseCase {
  final ChatRepository _repository;

  const DeleteMessageUseCase(this._repository);

  Future<void> call(String chatId, String messageId) {
    return _repository.deleteMessage(chatId, messageId);
  }
}
