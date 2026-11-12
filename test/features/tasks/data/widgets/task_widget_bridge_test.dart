import 'dart:convert';

import 'package:collab_tasks/features/tasks/data/widgets/task_widget_bridge.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_subtask.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('com.collab_tasks/task_widget');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  Object? initialNavigation;

  setUp(() {
    calls.clear();
    initialNavigation = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      _channel,
      (call) async {
        calls.add(call);
        if (call.method == 'takeInitialWidgetNavigation') {
          return initialNavigation;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      _channel,
      null,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  group('TaskWidgetBridge', () {
    test('sends compact task snapshots with metadata counts', () async {
      final deadline = DateTime.utc(2026, 11, 12, 9);
      final task = Task(
        id: 'task-1',
        createdAt: DateTime.utc(2026, 11, 1),
        title: 'Prepare release',
        description: 'Long description is not sent to the widget',
        priority: 3,
        isCompleted: true,
        isPinned: true,
        deadline: deadline,
        subtasks: const [
          TaskSubtask(id: 'sub-1', title: 'Done', isCompleted: true),
          TaskSubtask(id: 'sub-2', title: 'Pending'),
        ],
        attachments: const [
          TaskAttachment(id: 'file-1', name: 'brief', extension: 'pdf', sizeBytes: 123),
        ],
      );

      await TaskWidgetBridge.updateTasks([task]);

      expect(calls, hasLength(1));
      expect(calls.single.method, 'updateTasks');
      final payload = jsonDecode(calls.single.arguments as String) as List<dynamic>;
      expect(payload, hasLength(1));
      expect(payload.single, {
        'id': 'task-1',
        'title': 'Prepare release',
        'priority': 3,
        'isCompleted': true,
        'isPinned': true,
        'subtasksCount': 2,
        'completedSubtasksCount': 1,
        'deadlineMillis': deadline.millisecondsSinceEpoch,
        'attachmentsCount': 1,
      });
      expect(payload.single, isNot(contains('description')));
      expect(payload.single, isNot(contains('attachments')));
    });

    test('sends an empty snapshot when no tasks exist', () async {
      await TaskWidgetBridge.updateTasks(const []);

      expect(calls.single.method, 'updateTasks');
      expect(jsonDecode(calls.single.arguments as String), isEmpty);
    });

    test('parses initial task navigation', () async {
      initialNavigation = {'taskId': 'task-42', 'openHome': true, 'refreshTasks': true};

      final request = await TaskWidgetBridge.takeInitialNavigation();

      expect(request?.taskId, 'task-42');
      expect(request?.openHome, isTrue);
      expect(request?.refreshTasks, isTrue);
      expect(calls.single.method, 'takeInitialWidgetNavigation');
    });

    test('returns null when no initial navigation is pending', () async {
      expect(await TaskWidgetBridge.takeInitialNavigation(), isNull);
    });

    test('synchronizes each supported widget locale', () async {
      for (final locale in ['en', 'ru', 'uk']) {
        await TaskWidgetBridge.updateWidgetLocale(locale);
      }

      expect(calls.map((call) => call.method), everyElement('setWidgetLocale'));
      expect(calls.map((call) => call.arguments), ['en', 'ru', 'uk']);
    });

    test('ignores unsupported locales', () async {
      await TaskWidgetBridge.updateWidgetLocale('de');

      expect(calls, isEmpty);
    });

    test('does not invoke Android channel methods on non-Android platforms', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await TaskWidgetBridge.updateTasks(const []);
      await TaskWidgetBridge.updateWidgetLocale('en');
      expect(await TaskWidgetBridge.takeInitialNavigation(), isNull);

      expect(calls, isEmpty);
    });
  });
}
