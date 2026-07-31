import 'package:collab_tasks/core/text/text_utils.dart';
import 'package:collab_tasks/features/chats/domain/models/direct_chat_result.dart';
import 'package:collab_tasks/features/chats/domain/repositories/chat_repository.dart';
import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';

/// находит или создаёт личный чат с участником группы.
///
/// Принимает составной идентификатор участника [participantCompositeId]
/// (формат `<groupId>:<userId>`) и [groupId], возвращает [DirectChatResult].
class GetOrCreateDirectChatUseCase {
  const GetOrCreateDirectChatUseCase({
    required ChatRepository chatRepository,
    required WorkingGroupsRepository workingGroupsRepository,
  }) : _chatRepository = chatRepository,
       _workingGroupsRepository = workingGroupsRepository;

  final ChatRepository _chatRepository;
  final WorkingGroupsRepository _workingGroupsRepository;

  Future<DirectChatResult> call({
    required String groupId,
    required String participantCompositeId,
  }) async {
    final userId = participantCompositeId.substringAfterLast(':');
    final chatId = await _chatRepository.getOrCreateDirectChat(userId);
    final opponent = await _workingGroupsRepository.getParticipantById(
      groupId,
      participantCompositeId,
    );
    return DirectChatResult(chatId: chatId, opponentName: opponent.name);
  }
}
