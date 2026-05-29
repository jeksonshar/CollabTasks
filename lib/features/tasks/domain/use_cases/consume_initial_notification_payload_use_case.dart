import 'package:collab_tasks/features/tasks/data/notifications/notification_tap_payload.dart';
import 'package:collab_tasks/features/tasks/domain/services/task_notification_service.dart';

class ConsumeInitialNotificationPayloadUseCase {
  final TaskNotificationService _service;

  ConsumeInitialNotificationPayloadUseCase(this._service);

  NotificationTapPayload? call() {
    return _service.consumeInitialTapPayload();
  }
}
