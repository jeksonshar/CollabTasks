import 'dart:convert';

import 'package:collab_tasks/features/working_groups/data/widgets/groups_widget_bridge.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('com.collab_tasks/groups_widget');

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
        if (call.method == 'takeInitialGroupsWidgetNavigation') {
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

  group('GroupsWidgetBridge', () {
    test('serializes groups, deduplicates invited participants, and resolves assignees', () async {
      final now = DateTime.utc(2026, 11, 12);
      final group = WorkingGroup(
        id: 'group-1',
        title: 'Release team',
        description: 'Ship the release',
        createdAt: now,
        updatedAt: 17,
      );
      final participants = [
        const GroupParticipant(
          id: 'member:invite:user-1',
          groupId: 'group-1',
          userId: 'pending@example.com',
          name: 'Pending invite',
          updatedAt: 1,
        ),
        const GroupParticipant(
          id: 'participant:user-1',
          groupId: 'group-1',
          userId: 'user-1',
          name: 'Accepted member',
          updatedAt: 2,
        ),
        const GroupParticipant(
          id: 'participant:user-2',
          groupId: 'group-1',
          userId: 'me@example.com',
          name: 'Current user',
          updatedAt: 3,
        ),
      ];
      final task = GroupTask(
        id: 'group-task-1',
        groupId: 'group-1',
        createdAt: now,
        title: 'Review changes',
        description: 'Full task description stays local',
        priority: 2,
        isCompleted: true,
        assignedUserId: 'user-1',
      );

      await GroupsWidgetBridge.updateGroups(
        groups: [group],
        participantsByGroupId: {'group-1': participants},
        tasksByGroupId: {
          'group-1': [task],
        },
        currentUserEmail: 'ME@example.com',
      );

      expect(calls, hasLength(1));
      expect(calls.single.method, 'updateGroups');
      final payload = jsonDecode(calls.single.arguments as String) as List<dynamic>;
      expect(payload, hasLength(1));
      final serializedGroup = payload.single as Map<String, dynamic>;
      expect(serializedGroup['id'], 'group-1');
      expect(serializedGroup['title'], 'Release team');
      expect(serializedGroup['description'], 'Ship the release');

      final serializedParticipants = serializedGroup['participants'] as List<dynamic>;
      expect(serializedParticipants, hasLength(2));
      expect(
        serializedParticipants.map((item) => (item as Map<String, dynamic>)['name']),
        containsAll(['Accepted member', 'Current user']),
      );
      expect(
        serializedParticipants.map((item) => (item as Map<String, dynamic>)['name']),
        isNot(contains('Pending invite')),
      );
      final currentUser = serializedParticipants.cast<Map<String, dynamic>>().singleWhere(
        (participant) => participant['name'] == 'Current user',
      );
      expect(currentUser['isCurrentUser'], isTrue);
      final acceptedUser = serializedParticipants.cast<Map<String, dynamic>>().singleWhere(
        (participant) => participant['name'] == 'Accepted member',
      );
      expect(acceptedUser['isCurrentUser'], isFalse);

      final serializedTasks = serializedGroup['tasks'] as List<dynamic>;
      expect(serializedTasks, [
        {
          'id': 'group-task-1',
          'title': 'Review changes',
          'priority': 2,
          'isCompleted': true,
          'assignedUserName': 'Accepted member',
        },
      ]);
    });

    test('uses current user ID when email is unavailable', () async {
      final now = DateTime.utc(2026, 11, 12);
      await GroupsWidgetBridge.updateGroups(
        groups: [
          WorkingGroup(
            id: 'group-1',
            title: 'Group',
            description: '',
            createdAt: now,
            updatedAt: 0,
          ),
        ],
        participantsByGroupId: {
          'group-1': [
            const GroupParticipant(
              id: 'participant:user-1',
              groupId: 'group-1',
              userId: 'user-1',
              name: 'Me',
              updatedAt: 0,
            ),
          ],
        },
        tasksByGroupId: const {},
        currentUserId: 'user-1',
      );

      final payload = jsonDecode(calls.single.arguments as String) as List<dynamic>;
      final participant =
          ((payload.single as Map<String, dynamic>)['participants'] as List<dynamic>).single
              as Map<String, dynamic>;
      expect(participant['isCurrentUser'], isTrue);
    });

    test('sends an empty snapshot when no groups exist', () async {
      await GroupsWidgetBridge.updateGroups(
        groups: const [],
        participantsByGroupId: const {},
        tasksByGroupId: const {},
      );

      expect(calls.single.method, 'updateGroups');
      expect(jsonDecode(calls.single.arguments as String), isEmpty);
    });

    test('parses initial participant and task navigation payloads', () async {
      initialNavigation = {
        'openGroups': true,
        'participantGroupId': 'group-1',
        'participantId': 'user-1',
        'taskGroupId': 'group-2',
        'taskId': 'task-42',
      };

      final request = await GroupsWidgetBridge.takeInitialNavigation();

      expect(request?.openGroups, isTrue);
      expect(request?.participantGroupId, 'group-1');
      expect(request?.participantId, 'user-1');
      expect(request?.taskGroupId, 'group-2');
      expect(request?.taskId, 'task-42');
      expect(calls.single.method, 'takeInitialGroupsWidgetNavigation');
    });

    test('does not invoke Android channel methods on non-Android platforms', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await GroupsWidgetBridge.updateGroups(
        groups: const [],
        participantsByGroupId: const {},
        tasksByGroupId: const {},
      );
      expect(await GroupsWidgetBridge.takeInitialNavigation(), isNull);

      expect(calls, isEmpty);
    });
  });
}
