import '../../core/enums/task_filter_type.dart';
import '../../core/enums/task_sort_direction.dart';
import '../../core/enums/task_sort_type.dart';

class TaskViewPreferences {
  final TaskSortType sortType;
  final TaskSortDirection sortDirection;
  final TaskFilterType filterType;

  const TaskViewPreferences({
    this.sortType = TaskSortType.byDateCreated,
    this.sortDirection = TaskSortDirection.topToBottom,
    this.filterType = TaskFilterType.all,
  });

  TaskViewPreferences copyWith({
    TaskSortType? sortType,
    TaskSortDirection? sortDirection,
    TaskFilterType? filterType,
  }) {
    return TaskViewPreferences(
      sortType: sortType ?? this.sortType,
      sortDirection: sortDirection ?? this.sortDirection,
      filterType: filterType ?? this.filterType,
    );
  }
}
