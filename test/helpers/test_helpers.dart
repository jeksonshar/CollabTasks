import 'package:collab_tasks/core/enums/task_filter_type.dart';
import 'package:collab_tasks/core/enums/task_sort_direction.dart';
import 'package:collab_tasks/core/enums/task_sort_type.dart';
import 'package:collab_tasks/domain/models/task.dart';
import 'package:collab_tasks/domain/models/task_view_preferences.dart';
import 'package:mocktail/mocktail.dart';

void registerTestFallbackValues() {
  registerFallbackValue(Task(id: '0', title: '', createdAt: DateTime.now(), description: ''));

  registerFallbackValue(
    const TaskViewPreferences(
      sortType: TaskSortType.byDateCreated,
      sortDirection: TaskSortDirection.topToBottom,
      filterType: TaskFilterType.all,
    ),
  );
}
