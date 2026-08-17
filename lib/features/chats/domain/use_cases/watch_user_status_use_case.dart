import 'package:collab_tasks/features/chats/domain/models/user_status_entity.dart';
import 'package:collab_tasks/features/chats/domain/repositories/chat_repository.dart';

class WatchUserStatusUseCase {
  final ChatRepository _repository;

  const WatchUserStatusUseCase(this._repository);

  Stream<UserStatusEntity> call(String userId) {
    return _repository.watchUserStatus(userId);
  }
}
