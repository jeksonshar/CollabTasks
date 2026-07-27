import 'package:collab_tasks/features/chats/domain/models/group_chat_entity.dart';
import 'package:collab_tasks/features/chats/domain/repositories/chat_repository.dart';

class GetGroupChatUseCase {
  final ChatRepository _repository;

  const GetGroupChatUseCase(this._repository);

  Future<GroupChatEntity?> call(String chatId) {
    return _repository.getGroupChatById(chatId);
  }
}
