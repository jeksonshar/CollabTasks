import 'dart:async';

import 'package:collab_tasks/features/auth/domain/usecases/watch_auth_state_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/models/has_active_tasks_failure.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/add_group_task_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/delete_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_group_participants_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_group_tasks_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/invite_group_participant_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/leave_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/sync_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/update_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_event.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _participantsOnlyActionError = 'Only group participants can perform this action.';

class GroupDetailsBloc extends Bloc<GroupDetailsEvent, GroupDetailsState> {
  GroupDetailsBloc({
    required String groupId,
    required GetWorkingGroupUseCase getWorkingGroupUseCase,
    required GetGroupTasksUseCase getGroupTasksUseCase,
    required GetGroupParticipantsUseCase getGroupParticipantsUseCase,
    required AddGroupTaskUseCase addGroupTaskUseCase,
    required UpdateWorkingGroupUseCase updateWorkingGroupUseCase,
    required DeleteWorkingGroupUseCase deleteWorkingGroupUseCase,
    required InviteGroupParticipantUseCase inviteGroupParticipantUseCase,
    required LeaveWorkingGroupUseCase leaveWorkingGroupUseCase,
    required WatchAuthStateUseCase watchAuthStateUseCase,
    required SyncWorkingGroupUseCase syncWorkingGroupUseCase,
  }) : _groupId = groupId,
       _getWorkingGroupUseCase = getWorkingGroupUseCase,
       _getGroupTasksUseCase = getGroupTasksUseCase,
       _getGroupParticipantsUseCase = getGroupParticipantsUseCase,
       _addGroupTaskUseCase = addGroupTaskUseCase,
       _updateWorkingGroupUseCase = updateWorkingGroupUseCase,
       _deleteWorkingGroupUseCase = deleteWorkingGroupUseCase,
       _inviteGroupParticipantUseCase = inviteGroupParticipantUseCase,
       _leaveWorkingGroupUseCase = leaveWorkingGroupUseCase,
       _watchAuthStateUseCase = watchAuthStateUseCase,
       _syncWorkingGroupUseCase = syncWorkingGroupUseCase,
       super(const GroupDetailsState()) {
    on<GroupDetailsStarted>(_onStarted);
    on<GroupTaskFilterChanged>((event, emit) => emit(state.copyWith(filter: event.filter)));
    on<GroupTaskAdded>(_onTaskAdded);
    on<WorkingGroupUpdated>(_onGroupUpdated);
    on<WorkingGroupDeleted>(_onGroupDeleted);
    on<WorkingGroupLeft>(_onGroupLeft);
    on<GroupParticipantInvited>(_onParticipantInvited);
    on<GroupDetailsRefreshed>(_onRefreshed);
  }

  final String _groupId;
  final GetWorkingGroupUseCase _getWorkingGroupUseCase;
  final GetGroupTasksUseCase _getGroupTasksUseCase;
  final GetGroupParticipantsUseCase _getGroupParticipantsUseCase;
  final AddGroupTaskUseCase _addGroupTaskUseCase;
  final UpdateWorkingGroupUseCase _updateWorkingGroupUseCase;
  final DeleteWorkingGroupUseCase _deleteWorkingGroupUseCase;
  final InviteGroupParticipantUseCase _inviteGroupParticipantUseCase;
  final LeaveWorkingGroupUseCase _leaveWorkingGroupUseCase;
  final WatchAuthStateUseCase _watchAuthStateUseCase;
  final SyncWorkingGroupUseCase _syncWorkingGroupUseCase;

  Future<void> _onStarted(GroupDetailsStarted event, Emitter<GroupDetailsState> emit) async {
    emit(state.copyWith(status: GroupDetailsStatus.loading));

    // Получаем текущего сессионного пользователя через вызов UseCase
    final user = await _watchAuthStateUseCase().first;
    emit(state.copyWith(currentUserId: user?.id, currentUserEmail: user?.email));

    await emit.forEach<_GroupDetailsSnapshot>(
      _watchGroupDetails(),
      onData: (snapshot) => state.copyWith(
        status: GroupDetailsStatus.loaded,
        group: snapshot.group,
        participants: snapshot.participants,
        tasks: snapshot.tasks,
      ),
      onError: (error, _) =>
          state.copyWith(status: GroupDetailsStatus.error, errorMessage: error.toString()),
    );
  }

  Future<void> _onRefreshed(GroupDetailsRefreshed event, Emitter<GroupDetailsState> emit) async {
    try {
      await _syncWorkingGroupUseCase(_groupId);
    } catch (error) {
      emit(state.copyWith(status: GroupDetailsStatus.error, errorMessage: error.toString()));
    } finally {
      event.completer?.complete();
    }
  }

  /// Combines the group, participants and task streams, re-emitting whenever
  /// any of them changes.
  Stream<_GroupDetailsSnapshot> _watchGroupDetails() {
    final groupStream = _getWorkingGroupUseCase(_groupId);
    final participantsStream = _getGroupParticipantsUseCase(_groupId);
    final tasksStream = _getGroupTasksUseCase(_groupId);

    late final StreamController<_GroupDetailsSnapshot> controller;
    final subscriptions = <StreamSubscription<dynamic>>[];

    WorkingGroup? group;
    List<GroupParticipant>? participants;
    List<GroupTask>? tasks;
    var hasGroup = false;

    void emitIfReady() {
      if (hasGroup && participants != null && tasks != null) {
        controller.add(
          _GroupDetailsSnapshot(group: group, participants: participants!, tasks: tasks!),
        );
      }
    }

    controller = StreamController<_GroupDetailsSnapshot>(
      onListen: () {
        subscriptions
          ..add(
            groupStream.listen((value) {
              group = value;
              hasGroup = true;
              emitIfReady();
            }, onError: controller.addError),
          )
          ..add(
            participantsStream.listen((value) {
              participants = value;
              emitIfReady();
            }, onError: controller.addError),
          )
          ..add(
            tasksStream.listen((value) {
              tasks = value;
              emitIfReady();
            }, onError: controller.addError),
          );
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
        await controller.close();
      },
    );

    return controller.stream;
  }

  Future<void> _onTaskAdded(GroupTaskAdded event, Emitter<GroupDetailsState> emit) async {
    try {
      await _addGroupTaskUseCase(groupId: _groupId, draft: event.draft);
    } catch (error) {
      emit(state.copyWith(status: GroupDetailsStatus.error, errorMessage: error.toString()));
    }
  }

  Future<void> _onGroupUpdated(WorkingGroupUpdated event, Emitter<GroupDetailsState> emit) async {
    if (!_ensureCurrentUserIsParticipant(emit)) return;
    try {
      emit(state.copyWith(status: GroupDetailsStatus.saving));
      await _updateWorkingGroupUseCase(event.group);
      emit(state.copyWith(status: GroupDetailsStatus.loaded, group: event.group));
    } catch (error) {
      emit(state.copyWith(status: GroupDetailsStatus.error, errorMessage: error.toString()));
    }
  }

  Future<void> _onGroupDeleted(WorkingGroupDeleted event, Emitter<GroupDetailsState> emit) async {
    if (!_ensureCurrentUserIsParticipant(emit)) return;
    try {
      emit(state.copyWith(status: GroupDetailsStatus.saving));
      await _deleteWorkingGroupUseCase(_groupId);
      emit(state.copyWith(status: GroupDetailsStatus.deleted));
    } catch (error) {
      emit(state.copyWith(status: GroupDetailsStatus.error, errorMessage: error.toString()));
    }
  }

  Future<void> _onGroupLeft(WorkingGroupLeft event, Emitter<GroupDetailsState> emit) async {
    if (!_ensureCurrentUserIsParticipant(emit)) return;
    try {
      emit(state.copyWith(status: GroupDetailsStatus.saving));
      await _leaveWorkingGroupUseCase(_groupId);
      emit(state.copyWith(status: GroupDetailsStatus.left));
    } on HasActiveTasksFailure {
      emit(state.copyWith(status: GroupDetailsStatus.leaveRejectedWithActiveTasks));
    } catch (error) {
      emit(state.copyWith(status: GroupDetailsStatus.error, errorMessage: error.toString()));
    }
  }

  Future<void> _onParticipantInvited(
    GroupParticipantInvited event,
    Emitter<GroupDetailsState> emit,
  ) async {
    if (!_ensureCurrentUserIsParticipant(emit)) return;
    try {
      emit(state.copyWith(status: GroupDetailsStatus.saving));
      await _inviteGroupParticipantUseCase(groupId: _groupId, email: event.email);
      emit(
        state.copyWith(
          status: GroupDetailsStatus.loaded,
          participants: _participantsWithInvite(event.email),
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: GroupDetailsStatus.error, errorMessage: error.toString()));
    }
  }

  List<GroupParticipant> _participantsWithInvite(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return state.participants;

    final participant = GroupParticipant(
      id: '$_groupId:invite:$normalizedEmail',
      groupId: _groupId,
      userId: normalizedEmail,
      name: normalizedEmail,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    return [
      for (final existing in state.participants)
        if (existing.id != participant.id) existing,
      participant,
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  bool _ensureCurrentUserIsParticipant(Emitter<GroupDetailsState> emit) {
    if (state.isCurrentUserParticipant) return true;
    emit(
      state.copyWith(status: GroupDetailsStatus.error, errorMessage: _participantsOnlyActionError),
    );
    return false;
  }
}

class _GroupDetailsSnapshot {
  const _GroupDetailsSnapshot({
    required this.group,
    required this.participants,
    required this.tasks,
  });

  final WorkingGroup? group;
  final List<GroupParticipant> participants;
  final List<GroupTask> tasks;
}
