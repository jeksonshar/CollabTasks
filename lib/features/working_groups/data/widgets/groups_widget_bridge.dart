import 'dart:async';
import 'dart:convert';

import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridges working-group snapshots and widget taps to the Android home widget.
class GroupsWidgetBridge {
  GroupsWidgetBridge._();

  static const MethodChannel _channel = MethodChannel('com.collab_tasks/groups_widget');
  static final StreamController<GroupsWidgetNavigationRequest> _navigationController =
      StreamController<GroupsWidgetNavigationRequest>.broadcast();

  static Stream<GroupsWidgetNavigationRequest> get navigationRequests =>
      _navigationController.stream;

  static void initialize() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'widgetNavigation' && call.arguments is Map) {
        _navigationController.add(
          GroupsWidgetNavigationRequest.fromMap(Map<Object?, Object?>.from(call.arguments as Map)),
        );
      }
    });
  }

  static Future<GroupsWidgetNavigationRequest?> takeInitialNavigation() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final payload = await _channel.invokeMapMethod<String, dynamic>(
        'takeInitialGroupsWidgetNavigation',
      );
      if (payload == null) return null;
      return GroupsWidgetNavigationRequest.fromMap(payload);
    } on MissingPluginException {
      return null;
    }
  }

  static Future<void> updateGroups({
    required List<WorkingGroup> groups,
    required Map<String, List<GroupParticipant>> participantsByGroupId,
    required Map<String, List<GroupTask>> tasksByGroupId,
    String? currentUserId,
    String? currentUserEmail,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final payload = jsonEncode(
        groups
            .map((group) {
              final participants = _deduplicateParticipants(
                participantsByGroupId[group.id] ?? const <GroupParticipant>[],
              );
              final participantsByUserId = <String, GroupParticipant>{
                for (final participant in participants) participant.userId: participant,
              };
              return {
                'id': group.id,
                'title': group.title,
                'description': group.description,
                'participants': participants
                    .map(
                      (participant) => {
                        'id': participant.id,
                        'userId': participant.userId,
                        'name': participant.name,
                        'isCurrentUser': _isCurrentUser(
                          participant,
                          currentUserId: currentUserId,
                          currentUserEmail: currentUserEmail,
                        ),
                      },
                    )
                    .toList(growable: false),
                'tasks': (tasksByGroupId[group.id] ?? const <GroupTask>[])
                    .map(
                      (task) => {
                        'id': task.id,
                        'title': task.title,
                        'priority': task.priority,
                        'isCompleted': task.isCompleted,
                        'assignedUserName': task.assignedUserId == null
                            ? null
                            : participantsByUserId[task.assignedUserId]?.name,
                      },
                    )
                    .toList(growable: false),
              };
            })
            .toList(growable: false),
      );
      await _channel.invokeMethod<void>('updateGroups', payload);
    } on MissingPluginException {
      // Keep the app usable when the Android host does not register the widget channel.
    } on PlatformException {
      // A widget cache update must not interrupt group screens.
    }
  }
}

List<GroupParticipant> _deduplicateParticipants(List<GroupParticipant> participants) {
  final byIdentity = <String, GroupParticipant>{};
  for (final participant in participants) {
    final identity = participant.id.split(':').last.trim().toLowerCase();
    final existing = byIdentity[identity];
    final existingIsInvitation = existing?.id.toLowerCase().contains(':invite:') ?? false;
    final participantIsInvitation = participant.id.toLowerCase().contains(':invite:');
    if (existing == null || (existingIsInvitation && !participantIsInvitation)) {
      byIdentity[identity] = participant;
    }
  }
  return byIdentity.values.toList(growable: false);
}

bool _isCurrentUser(
  GroupParticipant participant, {
  required String? currentUserId,
  required String? currentUserEmail,
}) {
  final participantUserId = participant.userId.trim();
  final normalizedCurrentUserId = currentUserId?.trim();
  final normalizedCurrentUserEmail = currentUserEmail?.trim().toLowerCase();
  return (normalizedCurrentUserId != null &&
          normalizedCurrentUserId.isNotEmpty &&
          participantUserId == normalizedCurrentUserId) ||
      (normalizedCurrentUserEmail != null &&
          normalizedCurrentUserEmail.isNotEmpty &&
          participantUserId.toLowerCase() == normalizedCurrentUserEmail);
}

class GroupsWidgetNavigationRequest {
  const GroupsWidgetNavigationRequest({
    this.openGroups = false,
    this.participantGroupId,
    this.participantId,
    this.taskGroupId,
    this.taskId,
  });

  final bool openGroups;
  final String? participantGroupId;
  final String? participantId;
  final String? taskGroupId;
  final String? taskId;

  factory GroupsWidgetNavigationRequest.fromMap(Map<Object?, Object?> map) {
    return GroupsWidgetNavigationRequest(
      openGroups: map['openGroups'] == true,
      participantGroupId: map['participantGroupId'] as String?,
      participantId: map['participantId'] as String?,
      taskGroupId: map['taskGroupId'] as String?,
      taskId: map['taskId'] as String?,
    );
  }
}
