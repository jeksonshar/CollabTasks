import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';

class SyncWorkingGroupUseCase {
  const SyncWorkingGroupUseCase(this._repository);

  final WorkingGroupsRepository _repository;

  Future<void> call(String groupId) => _repository.syncGroup(groupId);
}
