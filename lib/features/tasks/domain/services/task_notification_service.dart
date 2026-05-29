import 'package:collab_tasks/core/notifications/notification_tap_payload.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';

abstract class TaskNotificationService {
  Stream<NotificationTapPayload> get notificationTapStream;

  NotificationTapPayload? consumeInitialTapPayload();

  Future<void> scheduleTaskNotifications(
    Task task, {
    required String reminderTitle,
    required String deadlineTitle,
  });

  Future<void> cancelTaskNotifications(String taskId);

  Future<void> syncTaskNotifications(
    List<Task> tasks, {
    required String reminderTitle,
    required String deadlineTitle,
  });
}
