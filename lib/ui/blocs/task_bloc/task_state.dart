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
  final String searchQuery;
  final TaskAction lastAction;
  final String? lastActionTaskTitle;

  const TaskState({
    this.status = TaskStatus.initial,
    this.tasks = const [],
    this.errorType,
    this.sortType = TaskSortType.byDateCreated,
    this.sortDirection = TaskSortDirection.topToBottom,
    this.filterType = TaskFilterType.all,
    this.searchQuery = '',
    this.lastAction = TaskAction.none,
    this.lastActionTaskTitle,
  });

  List<Task> get filteredTasks {
    List<Task> result = tasks;

    // Apply Filter
    switch (filterType) {
      case TaskFilterType.all:
        break;
      case TaskFilterType.completed:
        result = result.where((t) => t.isCompleted).toList();
        break;
      case TaskFilterType.incomplete:
        result = result.where((t) => !t.isCompleted).toList();
        break;
      case TaskFilterType.withFiles:
        result = result.where((t) => t.attachments.isNotEmpty).toList();
        break;
      case TaskFilterType.withoutFiles:
        result = result.where((t) => t.attachments.isEmpty).toList();
        break;
      case TaskFilterType.withDeadline:
        result = result.where((t) => t.deadline != null).toList();
        break;
      case TaskFilterType.withoutDeadline:
        result = result.where((t) => t.deadline == null).toList();
        break;
    }

    // Apply Search (only if 3 or more characters)
    if (searchQuery.length >= 3) {
      final query = searchQuery.toLowerCase();
      result = result.where((t) => t.title.toLowerCase().contains(query)).toList();
    }

    return result;
  }

  TaskState copyWith({
    TaskStatus? status,
    List<Task>? tasks,
    TaskErrorType? errorType,
    TaskSortType? sortType,
    TaskSortDirection? sortDirection,
    TaskFilterType? filterType,
    String? searchQuery,
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
      searchQuery: searchQuery ?? this.searchQuery,
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
    searchQuery,
    lastAction,
    lastActionTaskTitle,
  ];
}
