import 'package:collab_tasks/features/tasks/data/local/db/app_database.dart';
import 'package:collab_tasks/features/tasks/domain/models/errors/data_exception.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

abstract class TasksLocalDataSource {
  Stream<List<Task>> watchTasks({required String ownerId});

  Future<List<Task>> getTasks({required String ownerId});

  Future<Task?> getTask({required String ownerId, required String id});

  Future<void> upsertTask({required String ownerId, required Task task});

  Future<void> deleteTask({required String ownerId, required String id});
}

class DriftTasksLocalDataSource implements TasksLocalDataSource {
  final AppDatabase _db;

  const DriftTasksLocalDataSource(this._db);

  @override
  Stream<List<Task>> watchTasks({required String ownerId}) {
    return (_db.select(_db.taskEntity)..where((row) => row.taskOwnerId.equals(ownerId)))
        .watch()
        .map((rows) => rows.map((row) => row.toModel()).toList(growable: false));
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
    updatedAt: taskUpdatedAt,
  );
}
