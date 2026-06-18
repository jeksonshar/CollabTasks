import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';

class CreateWorkingGroupUseCase {
  const CreateWorkingGroupUseCase(this._repository);

  final WorkingGroupsRepository _repository;

  Future<WorkingGroup> call({required String title, required String description}) {
    return _repository.createGroup(title: title, description: description);
  }
}
