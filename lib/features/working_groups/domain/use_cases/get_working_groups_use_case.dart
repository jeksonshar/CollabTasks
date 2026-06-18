import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';

class GetWorkingGroupsUseCase {
  const GetWorkingGroupsUseCase(this._repository);

  final WorkingGroupsRepository _repository;

  Stream<List<WorkingGroup>> call() => _repository.watchGroups();
}
