import 'dart:typed_data';

import 'package:collab_tasks/core/enums/task_filter_type.dart';
import 'package:collab_tasks/core/enums/task_sort_direction.dart';
import 'package:collab_tasks/core/enums/task_sort_type.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';

abstract class TaskRepository {
  Stream<List<Task>> watchTasks({
    required String searchQuery,
    required TaskFilterType filterType,
    required TaskSortType sortType,
    required TaskSortDirection sortDirection,
  });

  Future<void> addTask(Task task);

  Future<void> updateTask(Task task);

  Future<void> deleteTask(String id);

  Future<void> toggleTask(String id);

  Future<void> syncTasks();

  Future<Uint8List> getAttachmentBytes(String storageKey);
}
