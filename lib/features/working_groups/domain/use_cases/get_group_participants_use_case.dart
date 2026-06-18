import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';

class GetGroupParticipantsUseCase {
  const GetGroupParticipantsUseCase(this._repository);

  final WorkingGroupsRepository _repository;

  Stream<List<GroupParticipant>> call(String groupId) => _repository.watchParticipants(groupId);
}
