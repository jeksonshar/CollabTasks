import 'package:collab_tasks/features/chats/domain/models/message_entity.dart';
import 'package:collab_tasks/features/chats/domain/repositories/chat_repository.dart';

class WatchMessagesUseCase {
  final ChatRepository _repository;

  const WatchMessagesUseCase(this._repository);

  Stream<List<MessageEntity>> call(String chatId) {
    return _repository.watchMessages(chatId);
  }
}
