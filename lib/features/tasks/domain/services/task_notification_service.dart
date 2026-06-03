import 'package:collab_tasks/features/tasks/data/notifications/notification_tap_payload.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';

abstract class TaskNotificationService {
  Stream<NotificationTapPayload> get notificationTapStream;

  NotificationTapPayload? consumeInitialTapPayload();

  Future<void> scheduleTaskNotifications(Task task);

  Future<void> cancelTaskNotifications(String taskId);

  Future<void> cancelAllNotifications();
}
