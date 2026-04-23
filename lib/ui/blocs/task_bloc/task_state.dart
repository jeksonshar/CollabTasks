import 'package:equatable/equatable.dart';

import '../../../core/enums/task_error_type.dart';
import '../../../core/enums/task_filter_type.dart';
import '../../../core/enums/task_sort_direction.dart';
import '../../../core/enums/task_sort_type.dart';
import '../../../domain/models/task.dart';

enum TaskStatus { initial, loading, success, failure }

enum TaskAction { add, update, delete, none }

class TaskState extends Equatable {
  final TaskStatus status;
  final List<Task> tasks;
  final TaskErrorType? errorType;
  final TaskSortType sortType;
  final TaskSortDirection sortDirection;
  final TaskFilterType filterType;
  final TaskAction lastAction;
  final String? lastActionTaskTitle;

  const TaskState({
    this.status = TaskStatus.initial,
    this.tasks = const [],
    this.errorType,
    this.sortType = TaskSortType.byDateCreated,
    this.sortDirection = TaskSortDirection.topToBottom,
    this.filterType = TaskFilterType.all,
    this.lastAction = TaskAction.none,
    this.lastActionTaskTitle,
  });

  List<Task> get filteredTasks {
    switch (filterType) {
      case TaskFilterType.all:
        return tasks;
      case TaskFilterType.completed:
        return tasks.where((t) => t.isCompleted).toList();
      case TaskFilterType.incomplete:
        return tasks.where((t) => !t.isCompleted).toList();
      case TaskFilterType.withFiles:
        return tasks.where((t) => t.attachments.isNotEmpty).toList();
      case TaskFilterType.withoutFiles:
        return tasks.where((t) => t.attachments.isEmpty).toList();
      case TaskFilterType.withDeadline:
        return tasks.where((t) => t.deadline != null).toList();
      case TaskFilterType.withoutDeadline:
        return tasks.where((t) => t.deadline == null).toList();
    }
  }

  TaskState copyWith({
    TaskStatus? status,
    List<Task>? tasks,
    TaskErrorType? errorType,
    TaskSortType? sortType,
    TaskSortDirection? sortDirection,
    TaskFilterType? filterType,
    TaskAction? lastAction,
    String? lastActionTaskTitle,
  }) {
    return TaskState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      errorType: errorType,
      sortType: sortType ?? this.sortType,
      sortDirection: sortDirection ?? this.sortDirection,
      filterType: filterType ?? this.filterType,
      lastAction: lastAction ?? this.lastAction,
      lastActionTaskTitle: lastActionTaskTitle ?? this.lastActionTaskTitle,
    );
  }

  @override
  List<Object?> get props => [
    status,
    tasks,
    errorType,
    sortType,
    sortDirection,
    filterType,
    lastAction,
    lastActionTaskTitle,
  ];
}
