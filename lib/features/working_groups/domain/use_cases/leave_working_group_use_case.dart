import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';

class LeaveWorkingGroupUseCase {
  const LeaveWorkingGroupUseCase(this._repository);

  final WorkingGroupsRepository _repository;

  Future<void> call(String groupId) => _repository.leaveGroup(groupId);
}
