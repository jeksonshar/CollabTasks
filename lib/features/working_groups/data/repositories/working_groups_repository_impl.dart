import 'dart:async';

import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:collab_tasks/features/auth/domain/repositories/auth_repository.dart';
import 'package:collab_tasks/features/tasks/domain/models/errors/data_exception.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_draft.dart';
import 'package:collab_tasks/features/working_groups/data/local/working_groups_local_data_source.dart';
import 'package:collab_tasks/features/working_groups/data/remote/working_groups_remote_data_source.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task_assignment_exception.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class WorkingGroupsRepositoryImpl implements WorkingGroupsRepository {
  WorkingGroupsRepositoryImpl({
    required WorkingGroupsLocalDataSource localDataSource,
    required WorkingGroupsRemoteDataSource remoteDataSource,
    required AuthRepository authRepository,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _authRepository = authRepository;

  final WorkingGroupsLocalDataSource _localDataSource;
  final WorkingGroupsRemoteDataSource _remoteDataSource;
  final AuthRepository _authRepository;
  final Map<String, StreamSubscription<List<GroupParticipant>>> _participantSubscriptions = {};
  final Map<String, StreamSubscription<List<GroupTask>>> _taskSubscriptions = {};
  StreamSubscription<List<WorkingGroup>>? _groupsSubscription;
  String? _subscribedUserId;

  @override
  Stream<List<WorkingGroup>> watchGroups() {
    return _authRepository.watchAuthState().asyncExpand((user) async* {
      if (user == null) {
        yield const <WorkingGroup>[];
        return;
      }
      _ensureGroupsSubscription(user);
      yield* _localDataSource.watchGroups();
    });
  }

  @override
  Future<void> syncGroups() async {
    final user = await _requireCurrentUser();
    final remoteGroups = await _remoteDataSource.fetchGroups(
      userId: user.id,
      userEmail: user.email,
    );

    // Upsert всех актуальных групп из remote в локальный кэш.
    for (final group in remoteGroups) {
      await _localDataSource.upsertGroup(group);
    }

    // Удаляем группы, которые есть локально, но отсутствуют на сервере
    // (т.е. были удалены с другого устройства).
    final remoteIds = remoteGroups.map((g) => g.id).toSet();
    final localGroups = await _localDataSource.getGroups();
    for (final local in localGroups) {
      if (!remoteIds.contains(local.id)) {
        await _localDataSource.deleteGroup(local.id);
      }
    }
  }

  @override
  Future<void> syncGroup(String groupId) async {
    final user = await _requireCurrentUser();
    final remoteGroups = await _remoteDataSource.fetchGroups(
      userId: user.id,
      userEmail: user.email,
    );
    final group = remoteGroups.cast<WorkingGroup?>().firstWhere(
      (g) => g?.id == groupId,
      orElse: () => null,
    );
    if (group != null) {
      await _localDataSource.upsertGroup(group);
    }

    final results = await Future.wait([
      _remoteDataSource.watchParticipants(groupId: groupId).first,
      _remoteDataSource.watchTasks(groupId: groupId).first,
    ]);

    final participants = results[0] as List<GroupParticipant>;
    final tasks = results[1] as List<GroupTask>;

    for (final participant in participants) {
      await _localDataSource.upsertParticipant(participant);
    }

    for (final task in tasks) {
      await _localDataSource.upsertTask(task.copyWith(isSynced: true));
    }

    await _participantSubscriptions.remove(groupId)?.cancel();
    await _taskSubscriptions.remove(groupId)?.cancel();
    _ensureGroupSubscriptions(groupId);
  }

  @override
  Stream<WorkingGroup?> watchGroup(String groupId) {
    unawaited(_ensureCurrentParticipantForGroup(groupId));
    _ensureGroupSubscriptions(groupId);
    return _localDataSource.watchGroup(groupId);
  }

  @override
  Stream<List<GroupParticipant>> watchParticipants(String groupId) {
    unawaited(_ensureCurrentParticipantForGroup(groupId));
    _ensureGroupSubscriptions(groupId);
    return _localDataSource.watchParticipants(groupId);
  }

  @override
  Stream<List<GroupTask>> watchGroupTasks(String groupId) {
    _ensureGroupSubscriptions(groupId);
    return _localDataSource.watchTasks(groupId);
  }

  @override
  Future<WorkingGroup> createGroup({required String title, required String description}) async {
    final user = await _requireCurrentUser();
    final now = DateTime.now();
    final updatedAt = now.millisecondsSinceEpoch;
    final group = WorkingGroup(
      id: const Uuid().v4(),
      title: title,
      description: description,
      createdAt: now,
      updatedAt: updatedAt,
    );
    final participant = _participantForUser(groupId: group.id, user: user, updatedAt: updatedAt);
    await _localDataSource.upsertGroup(group);
    await _localDataSource.upsertParticipant(participant);
    await _remoteDataSource.upsertGroup(
      group: group,
      participantUserIds: [user.id],
      participantEmails: [user.email],
    );
    await _remoteDataSource.upsertParticipant(participant);
    return group;
  }

  @override
  Future<void> updateGroup(WorkingGroup group) async {
    final updated = group.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch);
    await _localDataSource.upsertGroup(updated);
    await _tryRemote(() => _remoteDataSource.upsertGroup(group: updated));
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _localDataSource.deleteGroup(groupId);
    await _tryRemote(() => _remoteDataSource.deleteGroup(groupId));
  }

  @override
  Future<void> inviteParticipantByEmail({required String groupId, required String email}) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw DataException('Enter a valid email address.');
    }
    final updatedAt = DateTime.now().millisecondsSinceEpoch;
    final participant = GroupParticipant(
      id: '$groupId:invite:$normalizedEmail',
      groupId: groupId,
      userId: normalizedEmail,
      name: normalizedEmail,
      updatedAt: updatedAt,
    );
    await _localDataSource.upsertParticipant(participant);
    await _tryRemote(() async {
      await _remoteDataSource.inviteParticipantByEmail(groupId: groupId, email: normalizedEmail);
      await _remoteDataSource.upsertParticipant(participant);
    });
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    final user = await _requireCurrentUser();
    final normalizedEmail = user.email.trim().toLowerCase();
    final participants = await _localDataSource.getParticipants(groupId);
    final leavingParticipants = participants
        .where(
          (participant) =>
              participant.userId == user.id ||
              participant.userId.trim().toLowerCase() == normalizedEmail,
        )
        .toList(growable: false);

    if (leavingParticipants.isEmpty) {
      throw DataException('Current user is not a participant of this group.');
    }

    await _tryRemote(
      () => _remoteDataSource.leaveGroup(
        groupId: groupId,
        userId: user.id,
        userEmail: normalizedEmail,
        participantIds: leavingParticipants.map((participant) => participant.id).toList(),
      ),
    );
    for (final participant in leavingParticipants) {
      await _localDataSource.deleteParticipant(participant.id);
    }
    await _localDataSource.deleteGroup(groupId);
    await _participantSubscriptions.remove(groupId)?.cancel();
    await _taskSubscriptions.remove(groupId)?.cancel();
  }

  @override
  Future<void> addGroupTask({required String groupId, required TaskDraft draft}) async {
    final now = DateTime.now();
    final task = GroupTask.fromTask(
      groupId: groupId,
      task: Task(
        id: const Uuid().v4(),
        createdAt: now,
        title: draft.title,
        description: draft.descriptionJson,
        priority: draft.priority,
        attachments: draft.attachments,
        subtasks: draft.subtasks,
        isCompleted: draft.isCompleted,
        deadline: draft.deadline,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
    await _localDataSource.upsertTask(task);
    await _tryRemote(() => _remoteDataSource.upsertTask(task.copyWith(isSynced: true)));
  }

  @override
  Future<void> updateGroupTask(GroupTask task) async {
    final currentUser = await _requireCurrentUser();
    final participants = await _localDataSource.getParticipants(task.groupId);
    final assigned = _assignedParticipant(task, participants);
    if (assigned != null && assigned.userId != currentUser.id) {
      throw GroupTaskAssignmentException('Task is in progress by ${assigned.name}.');
    }
    final updated = task.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch);
    await _localDataSource.upsertTask(updated);
    await _tryRemote(() => _remoteDataSource.upsertTask(updated.copyWith(isSynced: true)));
  }

  @override
  Future<GroupTask> claimGroupTask({required String groupId, required String taskId}) async {
    final user = await _requireCurrentUser();
    final task = await _requireTask(groupId: groupId, taskId: taskId);
    final participant = await _ensureCurrentParticipant(groupId: groupId, user: user);
    if (task.assignedUserId != null &&
        task.assignedUserId!.isNotEmpty &&
        task.assignedUserId != participant.userId) {
      throw const GroupTaskAssignmentException('Task is already claimed by another participant.');
    }
    final updatedAt = DateTime.now().millisecondsSinceEpoch;
    final updated = task.copyWith(assignedUserId: participant.userId, updatedAt: updatedAt);
    await _localDataSource.upsertTask(updated);
    await _remoteDataSource.claimTask(
      groupId: groupId,
      taskId: taskId,
      participantId: participant.userId,
      updatedAt: updatedAt,
    );
    return updated;
  }

  @override
  Future<GroupTask> releaseGroupTask({required String groupId, required String taskId}) async {
    final user = await _requireCurrentUser();
    final task = await _requireTask(groupId: groupId, taskId: taskId);
    final participant = await _localDataSource.getParticipantByUserId(
      groupId: groupId,
      userId: user.id,
    );
    if (participant == null || task.assignedUserId != participant.userId) {
      throw const GroupTaskAssignmentException('Only current assignee can release this task.');
    }
    final updated = task.copyWith(
      assignedUserId: null,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _localDataSource.upsertTask(updated);
    await _tryRemote(() => _remoteDataSource.upsertTask(updated.copyWith(isSynced: true)));
    return updated;
  }

  void _ensureGroupsSubscription(AuthUser user) {
    if (_subscribedUserId == user.id && _groupsSubscription != null) return;
    _groupsSubscription?.cancel();
    _subscribedUserId = user.id;
    _groupsSubscription = _remoteDataSource
        .watchGroups(userId: user.id, userEmail: user.email)
        .listen(
          (groups) async {
            for (final group in groups) {
              await _localDataSource.upsertGroup(group);
              await _ensureCurrentParticipant(groupId: group.id, user: user);
              _ensureGroupSubscriptions(group.id);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('WorkingGroupsRepository.groupsSubscription failed: $error\n$stackTrace');
          },
        );
  }

  void _ensureGroupSubscriptions(String groupId) {
    _participantSubscriptions[groupId] ??= _remoteDataSource
        .watchParticipants(groupId: groupId)
        .listen(
          (participants) async {
            for (final participant in participants) {
              await _localDataSource.upsertParticipant(participant);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint(
              'WorkingGroupsRepository.participantsSubscription failed: $error\n$stackTrace',
            );
          },
        );
    _taskSubscriptions[groupId] ??= _remoteDataSource
        .watchTasks(groupId: groupId)
        .listen(
          (tasks) async {
            for (final task in tasks) {
              await _localDataSource.upsertTask(task.copyWith(isSynced: true));
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('WorkingGroupsRepository.tasksSubscription failed: $error\n$stackTrace');
          },
        );
  }

  Future<GroupParticipant> _ensureCurrentParticipant({
    required String groupId,
    required AuthUser user,
  }) async {
    final existing = await _localDataSource.getParticipantByUserId(
      groupId: groupId,
      userId: user.id,
    );
    if (existing != null) return existing;
    final participant = _participantForUser(
      groupId: groupId,
      user: user,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _localDataSource.upsertParticipant(participant);
    await _tryRemote(() => _remoteDataSource.upsertParticipant(participant));
    return participant;
  }

  Future<void> _ensureCurrentParticipantForGroup(String groupId) async {
    try {
      final user = await _requireCurrentUser();
      // Only self-heal the participant row for users who actually belong to the
      // group. This prevents a user who deliberately left from being silently
      // re-added when they (or a stale event) open the group again.
      final isMember = await _remoteDataSource.isGroupMember(
        groupId: groupId,
        userId: user.id,
        userEmail: user.email,
      );
      if (!isMember) return;
      await _ensureCurrentParticipant(groupId: groupId, user: user);
    } catch (error, stackTrace) {
      debugPrint('WorkingGroupsRepository.ensureCurrentParticipant failed: $error\n$stackTrace');
    }
  }

  GroupParticipant _participantForUser({
    required String groupId,
    required AuthUser user,
    required int updatedAt,
  }) {
    return GroupParticipant(
      id: '$groupId:${user.id}',
      groupId: groupId,
      userId: user.id,
      name: user.displayName?.trim().isNotEmpty == true ? user.displayName!.trim() : user.email,
      updatedAt: updatedAt,
    );
  }

  GroupParticipant? _assignedParticipant(GroupTask task, List<GroupParticipant> participants) {
    final assignedUserId = task.assignedUserId;
    if (assignedUserId == null || assignedUserId.isEmpty) return null;
    for (final participant in participants) {
      if (participant.id == assignedUserId) return participant;
    }
    return null;
  }

  Future<GroupTask> _requireTask({required String groupId, required String taskId}) async {
    final task = await _localDataSource.getTask(groupId: groupId, taskId: taskId);
    if (task == null) throw DataException('Group task $taskId was not found.');
    return task;
  }

  Future<AuthUser> _requireCurrentUser() async {
    final user = await _authRepository.watchAuthState().first;
    if (user == null) {
      throw DataException('Working groups require an authenticated user.');
    }
    return user;
  }

  Future<void> _tryRemote(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      debugPrint('WorkingGroupsRepository remote operation failed: $error\n$stackTrace');
    }
  }

  @override
  void clearSubscriptions() {
    // 1. Отменяем подписку на список групп
    _groupsSubscription?.cancel();
    _groupsSubscription = null;
    _subscribedUserId = null;

    // 2. В цикле закрываем все подписки на участников групп
    for (final subscription in _participantSubscriptions.values) {
      subscription.cancel();
    }
    _participantSubscriptions.clear();

    // 3. В цикле закрываем все подписки на задачи групп
    for (final subscription in _taskSubscriptions.values) {
      subscription.cancel();
    }
    _taskSubscriptions.clear();

    debugPrint('WorkingGroupsRepository: All remote subscriptions cleared safely.');
  }
}
