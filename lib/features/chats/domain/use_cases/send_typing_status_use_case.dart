import 'package:collab_tasks/features/chats/domain/repositories/chat_repository.dart';

class SendTypingStatusUseCase {
  final ChatRepository _repository;

  const SendTypingStatusUseCase(this._repository);

  Future<void> call(String chatId, bool isTyping) {
    return _repository.sendTypingStatus(chatId, isTyping);
  }
}
