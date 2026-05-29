import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/domain/services/task_notification_service.dart';

class SyncTaskNotificationsUseCase {
  final TaskNotificationService _service;

  SyncTaskNotificationsUseCase(this._service);

  Future<void> call(List<Task> tasks) {
    return _service.syncTaskNotifications(tasks);
  }
}
