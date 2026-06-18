import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/claim_group_task_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/release_group_task_use_case.dart';
import 'package:collab_tasks/features/working_groups/domain/use_cases/update_group_task_use_case.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/group_task_details/group_task_details_event.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/group_task_details/group_task_details_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GroupTaskDetailsBloc extends Bloc<GroupTaskDetailsEvent, GroupTaskDetailsState> {
  GroupTaskDetailsBloc({
    required GroupTask task,
    required ClaimGroupTaskUseCase claimGroupTaskUseCase,
    required ReleaseGroupTaskUseCase releaseGroupTaskUseCase,
    required UpdateGroupTaskUseCase updateGroupTaskUseCase,
  }) : _task = task,
       _claimGroupTaskUseCase = claimGroupTaskUseCase,
       _releaseGroupTaskUseCase = releaseGroupTaskUseCase,
       _updateGroupTaskUseCase = updateGroupTaskUseCase,
       super(const GroupTaskDetailsState()) {
    on<GroupTaskClaimRequested>(_onClaim);
    on<GroupTaskReleaseRequested>(_onRelease);
    on<GroupTaskUpdateRequested>(_onUpdate);
  }

  GroupTask _task;
  final ClaimGroupTaskUseCase _claimGroupTaskUseCase;
  final ReleaseGroupTaskUseCase _releaseGroupTaskUseCase;
  final UpdateGroupTaskUseCase _updateGroupTaskUseCase;

  Future<void> _onClaim(GroupTaskClaimRequested event, Emitter<GroupTaskDetailsState> emit) async {
    await _run(emit, () => _claimGroupTaskUseCase(groupId: _task.groupId, taskId: _task.id));
  }

  Future<void> _onRelease(
    GroupTaskReleaseRequested event,
    Emitter<GroupTaskDetailsState> emit,
  ) async {
    await _run(emit, () => _releaseGroupTaskUseCase(groupId: _task.groupId, taskId: _task.id));
  }

  Future<void> _onUpdate(
    GroupTaskUpdateRequested event,
    Emitter<GroupTaskDetailsState> emit,
  ) async {
    final updated = _task.copyWith(
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
      _task = updated;
    });
  }

  Future<void> _run(Emitter<GroupTaskDetailsState> emit, Future<void> Function() action) async {
    emit(state.copyWith(status: GroupTaskDetailsStatus.saving));
    try {
      await action();
      emit(state.copyWith(status: GroupTaskDetailsStatus.success));
    } catch (error) {
      emit(state.copyWith(status: GroupTaskDetailsStatus.error, errorMessage: error.toString()));
    }
  }
}
