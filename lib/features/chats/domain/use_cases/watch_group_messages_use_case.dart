import 'package:collab_tasks/features/chats/domain/models/message_entity.dart';
import 'package:collab_tasks/features/chats/domain/repositories/chat_repository.dart';

class WatchGroupMessagesUseCase {
  final ChatRepository _repository;

  const WatchGroupMessagesUseCase(this._repository);

  Stream<List<MessageEntity>> call(String groupId) {
    return _repository.watchGroupMessages(groupId);
  }
}
