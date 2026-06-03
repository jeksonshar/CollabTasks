import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';

abstract class TasksRemoteDataSource {
  Future<List<Task>> getTasks({required String ownerId});

  Future<Task?> getTask({required String ownerId, required String taskId});

  Future<void> createTask({required String ownerId, required Task task});

  Future<void> updateTask({required String ownerId, required Task task});

  Future<void> deleteTask({required String ownerId, required String taskId});

  Future<TaskAttachment> uploadFile({
    required String ownerId,
    required String taskId,
    required TaskAttachment file,
  });
}
