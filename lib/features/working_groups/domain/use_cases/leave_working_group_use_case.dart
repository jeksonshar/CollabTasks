import 'package:collab_tasks/features/auth/domain/usecases/watch_auth_state_use_case.dart';
import 'package:collab_tasks/features/tasks/domain/models/errors/data_exception.dart';
import 'package:collab_tasks/features/working_groups/domain/models/has_active_tasks_failure.dart';
import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';

class LeaveWorkingGroupUseCase {
  const LeaveWorkingGroupUseCase(this._repository, this._watchAuthStateUseCase);

  final WorkingGroupsRepository _repository;
  final WatchAuthStateUseCase _watchAuthStateUseCase;

  Future<void> call(String groupId) async {
    final user = await _watchAuthStateUseCase().first;
    if (user == null) {
      throw DataException('Working groups require an authenticated user.');
    }

    final hasActiveTasks = await _repository.hasActiveAssignedTasks(
      groupId: groupId,
      userId: user.id,
      userEmail: user.email,
    );
    if (hasActiveTasks) {
      throw const HasActiveTasksFailure();
    }

    await _repository.leaveGroup(groupId);
  }
}
