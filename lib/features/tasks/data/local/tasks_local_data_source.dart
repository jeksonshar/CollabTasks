import 'package:collab_tasks/core/enums/task_filter_type.dart';
import 'package:collab_tasks/core/enums/task_sort_direction.dart';
import 'package:collab_tasks/core/enums/task_sort_type.dart';
import 'package:collab_tasks/features/tasks/data/local/db/app_database.dart';
import 'package:collab_tasks/features/tasks/domain/models/errors/data_exception.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

abstract class TasksLocalDataSource {
  Stream<List<Task>> watchTasks({
    required String ownerId,
    required String searchQuery,
    required TaskFilterType filterType,
    required TaskSortType sortType,
    required TaskSortDirection sortDirection,
  });

  Future<List<Task>> getTasks({required String ownerId});

  Future<Task?> getTask({required String ownerId, required String id});

  Future<void> upsertTask({required String ownerId, required Task task});

  Future<void> deleteTask({required String ownerId, required String id});
}

class DriftTasksLocalDataSource implements TasksLocalDataSource {
  final AppDatabase _db;

  const DriftTasksLocalDataSource(this._db);

  @override
  Stream<List<Task>> watchTasks({
    required String ownerId,
    required String searchQuery,
    required TaskFilterType filterType,
    required TaskSortType sortType,
    required TaskSortDirection sortDirection,
  }) {
    final query = _db.select(_db.taskEntity)
      // 1. Жесткий фильтр по владельцу (ownerId)
      ..where((row) => row.taskOwnerId.equals(ownerId));

    // 2. Фильтрация по поисковой строке
    if (searchQuery.isNotEmpty) {
      query.where((row) => row.taskTitle.like('%$searchQuery%'));
    }

    // 3. Полная фильтрация по твоему энуму TaskFilterType
    switch (filterType) {
      case TaskFilterType.completed:
        query.where((row) => row.taskIsCompleted.equals(true));
        break;
      case TaskFilterType.incomplete:
        query.where((row) => row.taskIsCompleted.equals(false));
        break;
      case TaskFilterType.withDeadline:
        query.where((row) => row.taskDeadline.isNotNull());
        break;
      case TaskFilterType.withoutDeadline:
        query.where((row) => row.taskDeadline.isNull());
        break;
      case TaskFilterType.withFiles:
        // Таска с файлами: строка не null, не пустая и не содержит пустой JSON-массив '[]'
        query.where(
          (row) =>
              row.taskAttachments.isNotNull() &
              row.taskAttachments.equals('').not() &
              row.taskAttachments.equals('[]').not(),
        );
        break;
      case TaskFilterType.withoutFiles:
        // Таска без файлов: либо null, либо пустая строка, либо пустой JSON-массив
        query.where(
          (row) =>
              row.taskAttachments.isNull() |
              row.taskAttachments.equals('') |
              row.taskAttachments.equals('[]'),
        );
        break;
      case TaskFilterType.all:
        break;
    }

    // 4. Построение сортировки (Сначала закрепленные, затем пользовательская)
    query.orderBy([
      (row) => OrderingTerm(expression: row.taskIsPinned, mode: OrderingMode.desc),
      (row) {
        final isAscending = sortDirection == TaskSortDirection.topToBottom;
        final mode = isAscending ? OrderingMode.asc : OrderingMode.desc;

        switch (sortType) {
          case TaskSortType.byTitle:
            return OrderingTerm(expression: row.taskTitle, mode: mode);
          case TaskSortType.byPriority:
            return OrderingTerm(expression: row.taskPriority, mode: mode);
          case TaskSortType.byDateCreated:
            return OrderingTerm(expression: row.taskCreatedAt, mode: mode);
        }
      },
    ]);

    return query.watch().map((rows) => rows.map((row) => row.toModel()).toList(growable: false));
  }

  @override
  Future<List<Task>> getTasks({required String ownerId}) async {
    final rows = await (_db.select(
      _db.taskEntity,
    )..where((row) => row.taskOwnerId.equals(ownerId))).get();
    return rows.map((row) => row.toModel()).toList(growable: false);
  }

  @override
  Future<Task?> getTask({required String ownerId, required String id}) async {
    final row = await (_db.select(
      _db.taskEntity,
    )..where((t) => t.taskOwnerId.equals(ownerId) & t.taskId.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  @override
  Future<void> upsertTask({required String ownerId, required Task task}) async {
    try {
      final companion = TaskEntityCompanion.insert(
        taskId: task.id,
        taskOwnerId: Value(ownerId),
        taskTitle: Value(task.title),
        taskCreatedAt: task.createdAt,
        taskText: task.description,
        taskPriority: Value(task.priority),
        taskAttachments: task.attachments,
        taskSubtasks: Value(task.subtasks),
        taskIsCompleted: Value(task.isCompleted),
        taskDeadline: Value(task.deadline),
        taskIsPinned: Value(task.isPinned),
        taskIsSynced: Value(task.isSynced),
        taskUpdatedAt: Value(task.updatedAt),
      );

      await _db.into(_db.taskEntity).insert(companion, onConflict: DoUpdate((old) => companion));
    } catch (e) {
      throw DataException('Failed to upsert task: $e');
    }
  }

  @override
  Future<void> deleteTask({required String ownerId, required String id}) async {
    try {
      final deletedRows = await (_db.delete(
        _db.taskEntity,
      )..where((t) => t.taskOwnerId.equals(ownerId) & t.taskId.equals(id))).go();

      if (deletedRows == 0) {
        debugPrint('Warning: No task found with id $id to delete');
      }
    } catch (e) {
      throw DataException('Database error during deletion: $e');
    }
  }
}

extension TaskEntityDataMapper on TaskEntityData {
  Task toModel() => Task(
    id: taskId,
    createdAt: taskCreatedAt,
    title: taskTitle,
    description: taskText,
    priority: taskPriority,
    attachments: taskAttachments,
    subtasks: taskSubtasks,
    isCompleted: taskIsCompleted,
    deadline: taskDeadline,
    isPinned: taskIsPinned,
    isSynced: taskIsSynced,
    updatedAt: taskUpdatedAt,
  );
}
