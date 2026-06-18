import 'package:collab_tasks/features/tasks/domain/models/task_draft.dart';
import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';

class AddGroupTaskUseCase {
  const AddGroupTaskUseCase(this._repository);

  final WorkingGroupsRepository _repository;

  Future<void> call({required String groupId, required TaskDraft draft}) {
    return _repository.addGroupTask(groupId: groupId, draft: draft);
  }
}
