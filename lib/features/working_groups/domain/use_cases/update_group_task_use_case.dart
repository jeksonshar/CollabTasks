import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';

class UpdateGroupTaskUseCase {
  const UpdateGroupTaskUseCase(this._repository);

  final WorkingGroupsRepository _repository;

  Future<void> call(GroupTask task) => _repository.updateGroupTask(task);
}
