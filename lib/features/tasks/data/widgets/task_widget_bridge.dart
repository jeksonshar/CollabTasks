import 'dart:async';
import 'dart:convert';

import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridges the personal task list to the Android home-screen widget.
class TaskWidgetBridge {
  TaskWidgetBridge._();

  static const MethodChannel _channel = MethodChannel('com.collab_tasks/task_widget');
  static final StreamController<WidgetNavigationRequest> _navigationController =
      StreamController<WidgetNavigationRequest>.broadcast();

  static Stream<WidgetNavigationRequest> get navigationRequests => _navigationController.stream;

  static void initialize() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openTask' && call.arguments is String) {
        _navigationController.add(WidgetNavigationRequest(taskId: call.arguments as String));
      } else if (call.method == 'openHome') {
        _navigationController.add(const WidgetNavigationRequest(openHome: true));
      } else if (call.method == 'refreshTasks') {
        _navigationController.add(const WidgetNavigationRequest(refreshTasks: true));
      }
    });
  }

  static Future<WidgetNavigationRequest?> takeInitialNavigation() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final payload = await _channel.invokeMapMethod<String, dynamic>(
        'takeInitialWidgetNavigation',
      );
      if (payload == null) return null;
      return WidgetNavigationRequest(
        taskId: payload['taskId'] as String?,
        openHome: payload['openHome'] == true,
        refreshTasks: payload['refreshTasks'] == true,
      );
    } on MissingPluginException {
      return null;
    }
  }

  static Future<void> updateTasks(List<Task> tasks) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final payload = jsonEncode(
        tasks.map((task) {
          return {
            'id': task.id,
            'title': task.title,
            'priority': task.priority,
            'isCompleted': task.isCompleted,
            'isPinned': task.isPinned,
            'subtasksCount': task.subtasks.length,
            'completedSubtasksCount': task.subtasks.where((item) => item.isCompleted).length,
            'deadlineMillis': task.deadline?.millisecondsSinceEpoch,
            'attachmentsCount': task.attachments.length,
          };
        }).toList(),
      );
      await _channel.invokeMethod<void>('updateTasks', payload);
    } on MissingPluginException {
      // The Android host may not have registered the widget channel in tests.
    } on PlatformException {
      // A widget cache update should not interrupt the task screen.
    }
  }
}

class WidgetNavigationRequest {
  const WidgetNavigationRequest({this.taskId, this.openHome = false, this.refreshTasks = false});

  final String? taskId;
  final bool openHome;
  final bool refreshTasks;
}
