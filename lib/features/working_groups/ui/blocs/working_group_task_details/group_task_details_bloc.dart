import 'dart:async';

import 'package:collab_tasks/features/auth/domain/usecases/watch_auth_state_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/claim_group_task_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/release_group_task_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/update_group_task_use_case.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_task_details/group_task_details_event.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_task_details/group_task_details_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GroupTaskDetailsBloc extends Bloc<GroupTaskDetailsEvent, GroupTaskDetailsState> {
  GroupTaskDetailsBloc({
    required GroupTask task,
    required WatchAuthStateUseCase watchAuthStateUseCase,
    required ClaimGroupTaskUseCase claimGroupTaskUseCase,
    required ReleaseGroupTaskUseCase releaseGroupTaskUseCase,
    required UpdateGroupTaskUseCase updateGroupTaskUseCase,
  }) : _claimGroupTaskUseCase = claimGroupTaskUseCase,
       _releaseGroupTaskUseCase = releaseGroupTaskUseCase,
       _updateGroupTaskUseCase = updateGroupTaskUseCase,
       super(
         GroupTaskDetailsState(
           task: task,
           isAssignedToMe: false,
           isAssignedToOther: task.assignedUserId != null,
         ),
       ) {
    on<GroupTaskClaimRequested>(_onClaim);
    on<GroupTaskReleaseRequested>(_onRelease);
    on<GroupTaskUpdateRequested>(_onUpdate);
    on<UserAuthChanged>(_onUserAuthChanged);

    // Подписываемся на изменения состояния авторизации
    _authSubscription = watchAuthStateUseCase().listen((user) {
      add(UserAuthChanged(user));
    });
  }

  final ClaimGroupTaskUseCase _claimGroupTaskUseCase;
  final ReleaseGroupTaskUseCase _releaseGroupTaskUseCase;
  final UpdateGroupTaskUseCase _updateGroupTaskUseCase;

  // Ссылка на подписку, чтобы избежать утечек памяти
  late final StreamSubscription _authSubscription;

  // Храним текущий ID пользователя для корректного вычисления флагов при обновлении таски
  String? _currentUserId;

  void _onUserAuthChanged(UserAuthChanged event, Emitter<GroupTaskDetailsState> emit) {
    _currentUserId = event.user?.id; // Предполагается, что у AuthUser есть поле id (или uid)

    emit(
      state.copyWith(
        isAssignedToMe: state.task.assignedUserId == _currentUserId,
        isAssignedToOther:
            state.task.assignedUserId != null && state.task.assignedUserId != _currentUserId,
      ),
    );
  }

  Future<void> _onClaim(GroupTaskClaimRequested event, Emitter<GroupTaskDetailsState> emit) async {
    await _run(
      emit,
      () => _claimGroupTaskUseCase(groupId: state.task.groupId, taskId: state.task.id),
    );
  }

  Future<void> _onRelease(
    GroupTaskReleaseRequested event,
    Emitter<GroupTaskDetailsState> emit,
  ) async {
    await _run(
      emit,
      () => _releaseGroupTaskUseCase(groupId: state.task.groupId, taskId: state.task.id),
    );
  }

  Future<void> _onUpdate(
    GroupTaskUpdateRequested event,
    Emitter<GroupTaskDetailsState> emit,
  ) async {
    final updated = state.task.copyWith(
      title: event.draft.title,
      description: event.draft.descriptionJson,
      priority: event.draft.priority,
      attachments: event.draft.attachments,
      subtasks: event.draft.subtasks,
      isCompleted: event.draft.isCompleted,
      deadline: event.draft.deadline,
    );
    await _run(emit, () async {
      await _updateGroupTaskUseCase(updated);

      // Пересчитываем флаги на основе обновленной таски и сохраненного _currentUserId
      emit(
        state.copyWith(
          task: updated,
          status: GroupTaskDetailsStatus.success,
          isAssignedToMe: updated.assignedUserId == _currentUserId,
          isAssignedToOther:
              updated.assignedUserId != null && updated.assignedUserId != _currentUserId,
        ),
      );
    });
  }

  Future<void> _run(Emitter<GroupTaskDetailsState> emit, Future<void> Function() action) async {
    emit(state.copyWith(status: GroupTaskDetailsStatus.saving));
    try {
      await action();
      emit(state.copyWith(status: GroupTaskDetailsStatus.idle));
    } catch (error) {
      emit(state.copyWith(status: GroupTaskDetailsStatus.error, errorMessage: error.toString()));
    }
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
