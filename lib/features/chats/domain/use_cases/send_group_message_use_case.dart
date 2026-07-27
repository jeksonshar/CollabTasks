import 'package:collab_tasks/features/chats/domain/repositories/chat_repository.dart';

class SendGroupMessageUseCase {
  final ChatRepository _repository;

  const SendGroupMessageUseCase(this._repository);

  Future<void> call({required String groupId, required String content, required String senderId}) {
    return _repository.sendGroupMessage(groupId: groupId, content: content, senderId: senderId);
  }
}
