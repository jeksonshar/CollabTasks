import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';

class DeleteWorkingGroupUseCase {
  const DeleteWorkingGroupUseCase(this._repository);

  final WorkingGroupsRepository _repository;

  Future<void> call(String groupId) => _repository.deleteGroup(groupId);
}
