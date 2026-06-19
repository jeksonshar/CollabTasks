import 'package:collab_tasks/features/tasks/domain/models/task_draft.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task_filter.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:equatable/equatable.dart';

sealed class GroupDetailsEvent extends Equatable {
  const GroupDetailsEvent();

  @override
  List<Object?> get props => [];
}

class GroupDetailsStarted extends GroupDetailsEvent {
  const GroupDetailsStarted();
}

class GroupTaskFilterChanged extends GroupDetailsEvent {
  const GroupTaskFilterChanged(this.filter);

  final GroupTaskFilter filter;

  @override
  List<Object?> get props => [filter];
}

class GroupTaskAdded extends GroupDetailsEvent {
  const GroupTaskAdded(this.draft);

  final TaskDraft draft;

  @override
  List<Object?> get props => [draft];
}

class WorkingGroupUpdated extends GroupDetailsEvent {
  const WorkingGroupUpdated(this.group);

  final WorkingGroup group;

  @override
  List<Object?> get props => [group];
}

class WorkingGroupDeleted extends GroupDetailsEvent {
  const WorkingGroupDeleted();
}

class GroupParticipantInvited extends GroupDetailsEvent {
  const GroupParticipantInvited(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}
