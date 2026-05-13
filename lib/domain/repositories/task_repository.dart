import 'package:collab_tasks/domain/models/task.dart';

abstract class TaskRepository {
  Stream<List<Task>> watchTasks();

  Future<void> addTask(Task task);

  Future<void> updateTask(Task task);

  Future<void> deleteTask(String id);

  Future<void> toggleTask(String id);
}
