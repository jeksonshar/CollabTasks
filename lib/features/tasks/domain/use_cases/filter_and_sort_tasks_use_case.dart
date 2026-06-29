import 'package:collab_tasks/core/enums/task_filter_type.dart';
import 'package:collab_tasks/core/enums/task_sort_direction.dart';
import 'package:collab_tasks/core/enums/task_sort_type.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';

class FilterAndSortTasksUseCase {
  const FilterAndSortTasksUseCase();

  /// Applies filtering, searching, and sorting to a list of tasks.
  List<Task> call({
    required List<Task> tasks,
    required TaskFilterType filterType,
    required TaskSortType sortType,
    required TaskSortDirection sortDirection,
    required String searchQuery,
  }) {
    var result = _applyFilter(tasks, filterType);

    if (searchQuery.length >= 3) {
      result = _applySearch(result, searchQuery);
    }

    result = _applySort(result, sortType, sortDirection);

    return result;
  }

  List<Task> _applyFilter(List<Task> tasks, TaskFilterType filterType) {
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

  List<Task> _applySearch(List<Task> tasks, String query) {
    final lowerQuery = query.toLowerCase();
    return tasks.where((t) => t.title.toLowerCase().contains(lowerQuery)).toList();
  }

  List<Task> _applySort(List<Task> tasks, TaskSortType type, TaskSortDirection dir) {
    final pinned = tasks.where((t) => t.isPinned).toList();
    final others = tasks.where((t) => !t.isPinned).toList();

    int compare<T extends Comparable>(T a, T b) {
      return dir == TaskSortDirection.topToBottom ? a.compareTo(b) : b.compareTo(a);
    }

    void sortList(List<Task> list) {
      switch (type) {
        case TaskSortType.byDateCreated:
          list.sort((a, b) => compare(a.createdAt, b.createdAt));
          break;
        case TaskSortType.byPriority:
          list.sort((a, b) => compare(a.priority, b.priority));
          break;
        case TaskSortType.byTitle:
          list.sort((a, b) => compare(a.title, b.title));
          break;
      }
    }

    sortList(pinned);
    sortList(others);

    return [...pinned, ...others];
  }
}
