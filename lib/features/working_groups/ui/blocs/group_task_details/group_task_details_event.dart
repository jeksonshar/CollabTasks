import 'package:collab_tasks/features/tasks/domain/models/task_draft.dart';
import 'package:equatable/equatable.dart';

sealed class GroupTaskDetailsEvent extends Equatable {
  const GroupTaskDetailsEvent();

  @override
  List<Object?> get props => [];
}

class GroupTaskClaimRequested extends GroupTaskDetailsEvent {
  const GroupTaskClaimRequested();
}

class GroupTaskReleaseRequested extends GroupTaskDetailsEvent {
  const GroupTaskReleaseRequested();
}

class GroupTaskUpdateRequested extends GroupTaskDetailsEvent {
  const GroupTaskUpdateRequested(this.draft);

  final TaskDraft draft;

  @override
  List<Object?> get props => [draft];
}
