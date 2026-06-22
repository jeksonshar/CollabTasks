import 'package:collab_tasks/features/auth/domain/repositories/auth_repository.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/add_group_task_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/delete_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_group_participants_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_group_tasks_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/invite_group_participant_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/update_working_group_use_case.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/group_details/group_details_event.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/group_details/group_details_state.dart';
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
    required AuthRepository authRepository,
  }) : _groupId = groupId,
       _getWorkingGroupUseCase = getWorkingGroupUseCase,
       _getGroupTasksUseCase = getGroupTasksUseCase,
       _getGroupParticipantsUseCase = getGroupParticipantsUseCase,
       _addGroupTaskUseCase = addGroupTaskUseCase,
       _updateWorkingGroupUseCase = updateWorkingGroupUseCase,
       _deleteWorkingGroupUseCase = deleteWorkingGroupUseCase,
       _inviteGroupParticipantUseCase = inviteGroupParticipantUseCase,
       _authRepository = authRepository,
       super(const GroupDetailsState()) {
    on<GroupDetailsStarted>(_onStarted);
    on<GroupTaskFilterChanged>((event, emit) => emit(state.copyWith(filter: event.filter)));
    on<GroupTaskAdded>(_onTaskAdded);
    on<WorkingGroupUpdated>(_onGroupUpdated);
    on<WorkingGroupDeleted>(_onGroupDeleted);
    on<GroupParticipantInvited>(_onParticipantInvited);
  }

  final String _groupId;
  final GetWorkingGroupUseCase _getWorkingGroupUseCase;
  final GetGroupTasksUseCase _getGroupTasksUseCase;
  final GetGroupParticipantsUseCase _getGroupParticipantsUseCase;
  final AddGroupTaskUseCase _addGroupTaskUseCase;
  final UpdateWorkingGroupUseCase _updateWorkingGroupUseCase;
  final DeleteWorkingGroupUseCase _deleteWorkingGroupUseCase;
  final InviteGroupParticipantUseCase _inviteGroupParticipantUseCase;
  final AuthRepository _authRepository;

  Future<void> _onStarted(GroupDetailsStarted event, Emitter<GroupDetailsState> emit) async {
    emit(state.copyWith(status: GroupDetailsStatus.loading));
    final user = await _authRepository.watchAuthState().first;
    emit(state.copyWith(currentUserId: user?.id));

    await emit.forEach<_GroupDetailsSnapshot>(
      _getWorkingGroupUseCase(_groupId).asyncExpand((group) {
        return _getGroupParticipantsUseCase(_groupId).asyncExpand((participants) {
          return _getGroupTasksUseCase(_groupId).map(
            (tasks) =>
                _GroupDetailsSnapshot(group: group, participants: participants, tasks: tasks),
          );
        });
      }),
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
      emit(state.copyWith(status: GroupDetailsStatus.loaded));
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

  Future<void> _onParticipantInvited(
    GroupParticipantInvited event,
    Emitter<GroupDetailsState> emit,
  ) async {
    if (!_ensureCurrentUserIsParticipant(emit)) return;
    try {
      emit(state.copyWith(status: GroupDetailsStatus.saving));
      await _inviteGroupParticipantUseCase(groupId: _groupId, email: event.email);
      emit(state.copyWith(status: GroupDetailsStatus.loaded));
    } catch (error) {
      emit(state.copyWith(status: GroupDetailsStatus.error, errorMessage: error.toString()));
    }
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
