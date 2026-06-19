import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';

class GetWorkingGroupUseCase {
  const GetWorkingGroupUseCase(this._repository);

  final WorkingGroupsRepository _repository;

  Stream<WorkingGroup?> call(String groupId) => _repository.watchGroup(groupId);
}
