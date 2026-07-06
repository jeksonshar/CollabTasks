import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';

class ClaimGroupTaskUseCase {
  const ClaimGroupTaskUseCase(this._repository);

  final WorkingGroupsRepository _repository;

  Future<GroupTask> call({required String groupId, required String taskId}) {
    return _repository.claimGroupTask(groupId: groupId, taskId: taskId);
  }
}
