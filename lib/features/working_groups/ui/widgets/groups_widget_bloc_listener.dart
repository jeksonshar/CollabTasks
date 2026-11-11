import 'dart:async';

import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:collab_tasks/features/auth/domain/usecases/watch_auth_state_use_case.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/get_or_create_direct_chat_use_case.dart';
import 'package:collab_tasks/features/chats/ui/screens/chat_screen.dart';
import 'package:collab_tasks/features/working_groups/data/widgets/groups_widget_bridge.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_group_participants_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_group_tasks_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_working_groups_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/sync_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/ui/screens/working_group_task_details_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keeps the Android groups widget current and routes its taps into the app.
class GroupsWidgetBlocListener extends StatefulWidget {
  const GroupsWidgetBlocListener({required this.child, required this.onOpenGroups, super.key});

  final Widget child;
  final VoidCallback onOpenGroups;

  @override
  State<GroupsWidgetBlocListener> createState() => _GroupsWidgetBlocListenerState();
}

class _GroupsWidgetBlocListenerState extends State<GroupsWidgetBlocListener> {
  StreamSubscription<AuthUser?>? _authStateSubscription;
  StreamSubscription<GroupsWidgetNavigationRequest>? _navigationSubscription;
  StreamSubscription<List<WorkingGroup>>? _groupsSubscription;
  final Map<String, StreamSubscription<List<GroupParticipant>>> _participantSubscriptions = {};
  final Map<String, StreamSubscription<List<GroupTask>>> _taskSubscriptions = {};
  final Map<String, List<GroupParticipant>> _participantsByGroupId = {};
  final Map<String, List<GroupTask>> _tasksByGroupId = {};
  final Set<String> _syncingGroupIds = {};
  AuthUser? _currentUser;
  List<WorkingGroup> _groups = const [];

  @override
  void initState() {
    super.initState();
    GroupsWidgetBridge.initialize();
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    _authStateSubscription = getIt<WatchAuthStateUseCase>()().listen(
      (user) {
        _currentUser = user;
        _publishSnapshot();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[GroupsWidget] Failed to watch auth state: $error\n$stackTrace');
      },
    );
    _navigationSubscription = GroupsWidgetBridge.navigationRequests.listen(_handleNavigation);
    _groupsSubscription = getIt<GetWorkingGroupsUseCase>()().listen(
      _onGroupsChanged,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[GroupsWidget] Failed to watch groups: $error\n$stackTrace');
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final navigation = await GroupsWidgetBridge.takeInitialNavigation();
        if (mounted && navigation != null) {
          unawaited(_handleNavigation(navigation));
        }
      } on PlatformException catch (error, stackTrace) {
        debugPrint('[GroupsWidget] Initial navigation unavailable: $error\n$stackTrace');
      }
    });
  }

  void _onGroupsChanged(List<WorkingGroup> groups) {
    _groups = groups;
    final groupIds = groups.map((group) => group.id).toSet();
    for (final groupId in _participantSubscriptions.keys.toList()) {
      if (!groupIds.contains(groupId)) {
        unawaited(_participantSubscriptions.remove(groupId)?.cancel());
        unawaited(_taskSubscriptions.remove(groupId)?.cancel());
        _participantsByGroupId.remove(groupId);
        _tasksByGroupId.remove(groupId);
        _syncingGroupIds.remove(groupId);
      }
    }

    for (final group in groups) {
      if (_participantSubscriptions.containsKey(group.id)) continue;
      _participantSubscriptions[group.id] = getIt<GetGroupParticipantsUseCase>()(group.id).listen(
        (participants) {
          _participantsByGroupId[group.id] = participants;
          _publishSnapshot();
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('[GroupsWidget] Failed to watch participants for ${group.id}: $error');
        },
      );
      _taskSubscriptions[group.id] = getIt<GetGroupTasksUseCase>()(group.id).listen(
        (tasks) {
          _tasksByGroupId[group.id] = tasks;
          _publishSnapshot();
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('[GroupsWidget] Failed to watch tasks for ${group.id}: $error');
        },
      );
      _syncGroup(group.id);
    }
    _publishSnapshot();
  }

  void _syncGroup(String groupId) {
    if (!_syncingGroupIds.add(groupId)) return;
    unawaited(
      getIt<SyncWorkingGroupUseCase>()(groupId)
          .catchError((Object error, StackTrace stackTrace) {
            debugPrint('[GroupsWidget] Failed to sync group $groupId: $error\n$stackTrace');
          })
          .whenComplete(() {
            _syncingGroupIds.remove(groupId);
          }),
    );
  }

  void _publishSnapshot() {
    unawaited(
      GroupsWidgetBridge.updateGroups(
        groups: _groups,
        participantsByGroupId: _participantsByGroupId,
        tasksByGroupId: _tasksByGroupId,
        currentUserId: _currentUser?.id,
        currentUserEmail: _currentUser?.email,
      ),
    );
  }

  Future<void> _handleNavigation(GroupsWidgetNavigationRequest navigation) async {
    if (!mounted) return;
    if (navigation.openGroups) {
      widget.onOpenGroups();
      return;
    }

    final participantGroupId = navigation.participantGroupId;
    final participantCompositeId = navigation.participantId;
    if (participantGroupId != null && participantCompositeId != null) {
      await _openParticipantChat(participantGroupId, participantCompositeId);
      return;
    }

    final taskGroupId = navigation.taskGroupId;
    final taskId = navigation.taskId;
    if (taskGroupId != null && taskId != null) {
      await _openGroupTask(taskGroupId, taskId);
    }
  }

  Future<void> _openParticipantChat(String groupId, String participantCompositeId) async {
    final navigator = Navigator.of(context);
    final loadingRoute = MaterialPageRoute<void>(
      builder: (_) => const _WidgetNavigationLoadingScreen(),
    );
    unawaited(navigator.push(loadingRoute));

    try {
      final result = await getIt<GetOrCreateDirectChatUseCase>()(
        groupId: groupId,
        participantCompositeId: participantCompositeId,
      );
      if (!mounted || !loadingRoute.isCurrent) return;
      await navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChatScreen(chatId: result.chatId, opponentName: result.opponentName),
        ),
      );
    } catch (error, stackTrace) {
      if (loadingRoute.isCurrent) navigator.pop();
      debugPrint('[GroupsWidget] Failed to open direct chat: $error\n$stackTrace');
    }
  }

  Future<void> _openGroupTask(String groupId, String taskId) async {
    try {
      final participants = await getIt<GetGroupParticipantsUseCase>()(groupId).first;
      final tasks = await getIt<GetGroupTasksUseCase>()(groupId).first;
      GroupTask? task;
      for (final candidate in tasks) {
        if (candidate.id == taskId) {
          task = candidate;
          break;
        }
      }
      final matchedTask = task;
      if (!mounted || matchedTask == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              WorkingGroupTaskDetailsScreen(task: matchedTask, participants: participants),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('[GroupsWidget] Failed to open group task: $error\n$stackTrace');
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _navigationSubscription?.cancel();
    _groupsSubscription?.cancel();
    for (final subscription in _participantSubscriptions.values) {
      subscription.cancel();
    }
    for (final subscription in _taskSubscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _WidgetNavigationLoadingScreen extends StatelessWidget {
  const _WidgetNavigationLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
