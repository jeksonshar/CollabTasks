import 'package:collab_tasks/features/chats/domain/models/typing_status_entity.dart';
import 'package:collab_tasks/features/chats/domain/repositories/chat_repository.dart';

class WatchTypingStatusUseCase {
  final ChatRepository _repository;

  const WatchTypingStatusUseCase(this._repository);

  Stream<TypingStatusEntity> call(String chatId) {
    return _repository.watchTypingStatus(chatId);
  }
}
