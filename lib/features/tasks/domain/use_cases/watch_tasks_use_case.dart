import 'package:collab_tasks/core/enums/task_filter_type.dart';
import 'package:collab_tasks/core/enums/task_sort_direction.dart';
import 'package:collab_tasks/core/enums/task_sort_type.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/domain/repositories/task_repository.dart';

class WatchTasksUseCase {
  final TaskRepository repository;

  WatchTasksUseCase(this.repository);

  Stream<List<Task>> call({
    required String searchQuery,
    required TaskFilterType filterType,
    required TaskSortType sortType,
    required TaskSortDirection sortDirection,
  }) => repository.watchTasks(
    searchQuery: searchQuery,
    filterType: filterType,
    sortType: sortType,
    sortDirection: sortDirection,
  );
}
