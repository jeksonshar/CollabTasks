import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/domain/services/task_notification_service.dart';

class ScheduleTaskNotificationsUseCase {
  final TaskNotificationService _service;

  ScheduleTaskNotificationsUseCase(this._service);

  Future<void> call(Task task, {required String reminderTitle, required String deadlineTitle}) {
    return _service.scheduleTaskNotifications(
      task,
      reminderTitle: reminderTitle,
      deadlineTitle: deadlineTitle,
    );
  }
}
