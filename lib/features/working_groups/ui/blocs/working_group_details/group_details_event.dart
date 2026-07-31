import 'dart:async';

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

class WorkingGroupLeft extends GroupDetailsEvent {
  const WorkingGroupLeft();
}

class GroupParticipantInvited extends GroupDetailsEvent {
  const GroupParticipantInvited(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

class GroupDetailsRefreshed extends GroupDetailsEvent {
  const GroupDetailsRefreshed({this.completer});

  final Completer<void>? completer;

  @override
  List<Object?> get props => [completer];
}

/// Пользователь нажал на участника группы — нужно открыть личный чат.
class GroupParticipantChatOpened extends GroupDetailsEvent {
  const GroupParticipantChatOpened({required this.groupId, required this.participantCompositeId});

  final String groupId;
  final String participantCompositeId;

  @override
  List<Object?> get props => [groupId, participantCompositeId];
}

/// UI уведомляет BLoC, что [GroupDetailsState.pendingDirectChat] был прочитан
/// и его нужно сбросить в `null`, чтобы избежать повторной навигации.
class GroupDirectChatConsumed extends GroupDetailsEvent {
  const GroupDirectChatConsumed();
}
