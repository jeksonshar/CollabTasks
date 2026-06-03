import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/domain/services/task_notification_service.dart';

class ScheduleTaskNotificationsUseCase {
  final TaskNotificationService _service;

  ScheduleTaskNotificationsUseCase(this._service);

  Future<void> call(Task task) {
    return _service.scheduleTaskNotifications(task);
  }
}
