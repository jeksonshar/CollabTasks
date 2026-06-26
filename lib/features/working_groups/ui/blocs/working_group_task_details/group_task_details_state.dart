import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:equatable/equatable.dart';

enum GroupTaskDetailsStatus { idle, saving, success, error }

class GroupTaskDetailsState extends Equatable {
  const GroupTaskDetailsState({
    required this.task,
    this.status = GroupTaskDetailsStatus.idle,
    this.errorMessage,
    this.isAssignedToMe = false,
    this.isAssignedToOther = false,
  });

  final GroupTask task;
  final GroupTaskDetailsStatus status;
  final String? errorMessage;

  // Презентационная логика инкапсулирована в стейте
  final bool isAssignedToMe;
  final bool isAssignedToOther;

  GroupTaskDetailsState copyWith({
    GroupTask? task,
    GroupTaskDetailsStatus? status,
    String? errorMessage,
    bool? isAssignedToMe,
    bool? isAssignedToOther,
  }) {
    return GroupTaskDetailsState(
      task: task ?? this.task,
      status: status ?? this.status,
      errorMessage: errorMessage,
      // Сбрасываем ошибку, если не передана явно
      isAssignedToMe: isAssignedToMe ?? this.isAssignedToMe,
      isAssignedToOther: isAssignedToOther ?? this.isAssignedToOther,
    );
  }

  @override
  List<Object?> get props => [task, status, errorMessage, isAssignedToMe, isAssignedToOther];
}
