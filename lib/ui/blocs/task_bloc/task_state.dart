import 'package:equatable/equatable.dart';

import '../../../core/enums/task_error_type.dart';
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
  final TaskAction lastAction;
  final String? lastActionTaskTitle;

  const TaskState({
    this.status = TaskStatus.initial,
    this.tasks = const [],
    this.errorType,
    this.sortType = TaskSortType.byDateCreated,
    this.sortDirection = TaskSortDirection.topToBottom,
    this.lastAction = TaskAction.none,
    this.lastActionTaskTitle,
  });

  TaskState copyWith({
    TaskStatus? status,
    List<Task>? tasks,
    TaskErrorType? errorType,
    TaskSortType? sortType,
    TaskSortDirection? sortDirection,
    TaskAction? lastAction,
    String? lastActionTaskTitle,
  }) {
    return TaskState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      errorType: errorType,
      sortType: sortType ?? this.sortType,
      sortDirection: sortDirection ?? this.sortDirection,
      lastAction: lastAction ?? this.lastAction,
      lastActionTaskTitle: lastActionTaskTitle ?? this.lastActionTaskTitle,
    );
  }

  @override
  List<Object?> get props => [status, tasks, errorType, sortType, sortDirection];
}
