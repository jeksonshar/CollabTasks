import 'package:collab_tasks/features/tasks/domain/services/task_notification_service.dart';

class CancelTaskNotificationsUseCase {
  final TaskNotificationService _service;

  CancelTaskNotificationsUseCase(this._service);

  Future<void> call(String taskId) {
    return _service.cancelTaskNotifications(taskId);
  }
}
