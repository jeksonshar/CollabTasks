import 'package:collab_tasks/features/auth/domain/repositories/auth_repository.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/add_group_task_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_group_participants_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/get_group_tasks_use_case.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/group_details/group_details_event.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/group_details/group_details_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GroupDetailsBloc extends Bloc<GroupDetailsEvent, GroupDetailsState> {
  GroupDetailsBloc({
    required String groupId,
    required GetGroupTasksUseCase getGroupTasksUseCase,
    required GetGroupParticipantsUseCase getGroupParticipantsUseCase,
    required AddGroupTaskUseCase addGroupTaskUseCase,
    required AuthRepository authRepository,
  }) : _groupId = groupId,
       _getGroupTasksUseCase = getGroupTasksUseCase,
       _getGroupParticipantsUseCase = getGroupParticipantsUseCase,
       _addGroupTaskUseCase = addGroupTaskUseCase,
       _authRepository = authRepository,
       super(const GroupDetailsState()) {
    on<GroupDetailsStarted>(_onStarted);
    on<GroupTaskFilterChanged>((event, emit) => emit(state.copyWith(filter: event.filter)));
    on<GroupTaskAdded>(_onTaskAdded);
  }

  final String _groupId;
  final GetGroupTasksUseCase _getGroupTasksUseCase;
  final GetGroupParticipantsUseCase _getGroupParticipantsUseCase;
  final AddGroupTaskUseCase _addGroupTaskUseCase;
  final AuthRepository _authRepository;

  Future<void> _onStarted(GroupDetailsStarted event, Emitter<GroupDetailsState> emit) async {
    emit(state.copyWith(status: GroupDetailsStatus.loading));
    final user = await _authRepository.watchAuthState().first;
    emit(state.copyWith(currentUserId: user?.id));

    await emit.forEach<_GroupDetailsSnapshot>(
      _getGroupParticipantsUseCase(_groupId).asyncExpand((participants) {
        return _getGroupTasksUseCase(
          _groupId,
        ).map((tasks) => _GroupDetailsSnapshot(participants: participants, tasks: tasks));
      }),
      onData: (snapshot) => state.copyWith(
        status: GroupDetailsStatus.loaded,
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
}

class _GroupDetailsSnapshot {
  const _GroupDetailsSnapshot({required this.participants, required this.tasks});

  final List<GroupParticipant> participants;
  final List<GroupTask> tasks;
}
