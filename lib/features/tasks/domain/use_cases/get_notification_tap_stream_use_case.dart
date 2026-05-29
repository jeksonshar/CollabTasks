import 'package:collab_tasks/core/notifications/notification_tap_payload.dart';
import 'package:collab_tasks/features/tasks/domain/services/task_notification_service.dart';

class GetNotificationTapStreamUseCase {
  final TaskNotificationService _service;

  GetNotificationTapStreamUseCase(this._service);

  Stream<NotificationTapPayload> call() {
    return _service.notificationTapStream;
  }
}
