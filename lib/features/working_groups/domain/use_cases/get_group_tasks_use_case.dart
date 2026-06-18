import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';

class GetGroupTasksUseCase {
  const GetGroupTasksUseCase(this._repository);

  final WorkingGroupsRepository _repository;

  Stream<List<GroupTask>> call(String groupId) => _repository.watchGroupTasks(groupId);
}
