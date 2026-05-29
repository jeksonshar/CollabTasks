import 'dart:convert';

import 'package:collab_tasks/core/notifications/task_notification_event_type.dart';

class NotificationTapPayload {
  final String taskId;
  final TaskNotificationEventType eventType;

  const NotificationTapPayload({required this.taskId, required this.eventType});

  String toJson() {
    return jsonEncode({'taskId': taskId, 'eventType': eventType.name});
  }

  static NotificationTapPayload? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) {
        return null;
      }

      final taskId = map['taskId'] as String?;
      final eventName = map['eventType'] as String?;
      if (taskId == null || taskId.isEmpty || eventName == null || eventName.isEmpty) {
        return null;
      }

      final eventType = TaskNotificationEventType.values.where((e) => e.name == eventName).first;
      return NotificationTapPayload(taskId: taskId, eventType: eventType);
    } catch (_) {
      return null;
    }
  }
}
