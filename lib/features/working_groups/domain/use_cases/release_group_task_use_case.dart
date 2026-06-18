import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';

class ReleaseGroupTaskUseCase {
  const ReleaseGroupTaskUseCase(this._repository);

  final WorkingGroupsRepository _repository;

  Future<void> call({required String groupId, required String taskId}) {
    return _repository.releaseGroupTask(groupId: groupId, taskId: taskId);
  }
}
