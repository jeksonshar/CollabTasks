import 'package:collab_tasks/features/chats/domain/models/chat_entity.dart';
import 'package:collab_tasks/features/chats/domain/repositories/chat_repository.dart';

class GetChatUseCase {
  final ChatRepository _repository;

  const GetChatUseCase(this._repository);

  Future<ChatEntity?> call(String chatId) {
    return _repository.getChatById(chatId);
  }
}
