import 'package:collab_tasks/core/paging/chats_paging_constants.dart';
import 'package:collab_tasks/features/chats/domain/repositories/chat_repository.dart';

class LoadMoreMessagesUseCase {
  final ChatRepository _chatRepository;

  const LoadMoreMessagesUseCase(this._chatRepository);

  Future<bool> call(
    String chatId, {
    required int beforeCreatedAtMillis,
    required String beforeId,
    int limit = limitOnPage,
  }) {
    return _chatRepository.loadMoreMessages(
      chatId,
      beforeCreatedAtMillis: beforeCreatedAtMillis,
      beforeId: beforeId,
      limit: limit,
    );
  }
}
