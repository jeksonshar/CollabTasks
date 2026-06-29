import 'package:collab_tasks/core/enums/task_error_type.dart';
import 'package:collab_tasks/core/enums/task_filter_type.dart';
import 'package:collab_tasks/core/enums/task_sort_direction.dart';
import 'package:collab_tasks/core/enums/task_sort_type.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:equatable/equatable.dart';

enum TaskStatus { initial, loading, success, failure }

enum TaskAction { add, update, delete, none }

class TaskState extends Equatable {
  final TaskStatus status;

  // ВАЖНО: теперь здесь всегда хранится уже отфильтрованный и отсортированный список для UI
  final List<Task> tasks;
  final TaskErrorType? errorType;
  final TaskSortType sortType;
  final TaskSortDirection sortDirection;
  final TaskFilterType filterType;
  final String searchQuery;
  final TaskAction lastAction;
  final String? lastActionTaskTitle;
  final String? highlightedTaskId;
  final int highlightedTaskVersion;

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
    this.highlightedTaskId,
    this.highlightedTaskVersion = 0,
  });

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
    String? highlightedTaskId,
    int? highlightedTaskVersion,
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
      lastActionTaskTitle: lastActionTaskTitle,
      highlightedTaskId: highlightedTaskId ?? this.highlightedTaskId,
      highlightedTaskVersion: highlightedTaskVersion ?? this.highlightedTaskVersion,
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
    highlightedTaskId,
    highlightedTaskVersion,
  ];
}
