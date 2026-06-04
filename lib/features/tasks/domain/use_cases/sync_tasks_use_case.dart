import 'package:collab_tasks/features/tasks/domain/repositories/task_repository.dart';

class SyncTasksUseCase {
  final TaskRepository _repository;

  const SyncTasksUseCase(this._repository);

  Future<void> call() => _repository.syncTasks();
}
