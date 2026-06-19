import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task_filter.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:equatable/equatable.dart';

enum GroupDetailsStatus { loading, loaded, saving, deleted, error }

class GroupDetailsState extends Equatable {
  const GroupDetailsState({
    this.status = GroupDetailsStatus.loading,
    this.participants = const [],
    this.tasks = const [],
    this.filter = GroupTaskFilter.all,
    this.currentUserId,
    this.group,
    this.errorMessage,
  });

  final GroupDetailsStatus status;
  final List<GroupParticipant> participants;
  final List<GroupTask> tasks;
  final GroupTaskFilter filter;
  final String? currentUserId;
  final WorkingGroup? group;
  final String? errorMessage;

  List<GroupTask> get visibleTasks {
    return switch (filter) {
      GroupTaskFilter.all => tasks,
      GroupTaskFilter.available =>
        tasks
            .where((task) => task.assignedUserId == null || task.assignedUserId!.isEmpty)
            .toList(growable: false),
      GroupTaskFilter.mine =>
        tasks
            .where((task) {
              final participant = participantById(task.assignedUserId);
              return participant?.userId == currentUserId;
            })
            .toList(growable: false),
    };
  }

  GroupParticipant? participantById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final participant in participants) {
      if (participant.id == id) return participant;
    }
    return null;
  }

  GroupDetailsState copyWith({
    GroupDetailsStatus? status,
    List<GroupParticipant>? participants,
    List<GroupTask>? tasks,
    GroupTaskFilter? filter,
    String? currentUserId,
    WorkingGroup? group,
    String? errorMessage,
  }) {
    return GroupDetailsState(
      status: status ?? this.status,
      participants: participants ?? this.participants,
      tasks: tasks ?? this.tasks,
      filter: filter ?? this.filter,
      currentUserId: currentUserId ?? this.currentUserId,
      group: group ?? this.group,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    participants,
    tasks,
    filter,
    currentUserId,
    group,
    errorMessage,
  ];
}
