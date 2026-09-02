import 'package:collab_tasks/core/paging/chats_paging_constants.dart';
import 'package:collab_tasks/features/chats/domain/repositories/chat_repository.dart';

class LoadMoreGroupMessagesUseCase {
  final ChatRepository _chatRepository;

  const LoadMoreGroupMessagesUseCase(this._chatRepository);

  Future<bool> call(
    String groupId, {
    required int beforeCreatedAtMillis,
    required String beforeId,
    int limit = limitOnPage,
  }) {
    return _chatRepository.loadMoreGroupMessages(
      groupId,
      beforeCreatedAtMillis: beforeCreatedAtMillis,
      beforeId: beforeId,
      limit: limit,
    );
  }
}
