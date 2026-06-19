import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';

class UpdateWorkingGroupUseCase {
  const UpdateWorkingGroupUseCase(this._repository);

  final WorkingGroupsRepository _repository;

  Future<void> call(WorkingGroup group) => _repository.updateGroup(group);
}
