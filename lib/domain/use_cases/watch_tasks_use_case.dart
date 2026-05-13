import 'package:collab_tasks/domain/models/task.dart';
import 'package:collab_tasks/domain/repositories/task_repository.dart';

class WatchTasksUseCase {
  final TaskRepository repository;

  WatchTasksUseCase(this.repository);

  Stream<List<Task>> call() => repository.watchTasks();
}
