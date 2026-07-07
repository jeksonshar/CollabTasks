import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';

class SyncWorkingGroupsUseCase {
  const SyncWorkingGroupsUseCase(this._repository);

  final WorkingGroupsRepository _repository;

  Future<void> call() => _repository.syncGroups();
}
