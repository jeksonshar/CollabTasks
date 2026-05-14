import 'package:collab_tasks/data/local/db/app_database.dart';
import 'package:collab_tasks/domain/models/errors/data_exception.dart';
import 'package:collab_tasks/domain/models/task.dart';
import 'package:collab_tasks/domain/repositories/task_repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter/cupertino.dart';

class TaskRepositoryImpl implements TaskRepository {
  final AppDatabase _db;

  TaskRepositoryImpl(this._db);

  Future<void> _upsertTask(Task task) async {
    try {
      final companion = TaskEntityCompanion.insert(
        taskId: task.id,
        taskTitle: Value(task.title),
        taskCreatedAt: task.createdAt,
        taskText: task.description,
        taskPriority: Value(task.priority),
        taskAttachments: task.attachments,
        taskSubtasks: Value(task.subtasks),
        taskIsCompleted: Value(task.isCompleted),
        taskDeadline: Value(task.deadline),
        taskIsPinned: Value(task.isPinned),
      );

      await _db.into(_db.taskEntity).insert(companion, onConflict: DoUpdate((old) => companion));
    } catch (e) {
      throw DataException("Failed to upsert task: $e");
    }
  }

  @override
  Future<void> addTask(Task task) => _upsertTask(task);

  @override
  Future<void> updateTask(Task task) => _upsertTask(task);

  @override
  Future<void> deleteTask(String id) async {
    try {
      final deletedRows = await (_db.delete(
        _db.taskEntity,
      )..where((t) => t.taskId.equals(id))).go();

      if (deletedRows == 0) {
        debugPrint("Warning: No task found with id $id to delete");
      }
    } catch (e) {
      throw DataException("Database error during deletion: $e");
    }
  }

  @override
  Stream<List<Task>> watchTasks() {
    return _db
        .select(_db.taskEntity)
        .watch()
        .map((rows) => rows.map((row) => row.toModel()).toList());
  }

  @override
  Future<void> toggleTask(String id) async {
    try {
      await _db.transaction(() async {
        final query = _db.select(_db.taskEntity)..where((t) => t.taskId.equals(id));
        final task = await query.getSingleOrNull(); // Безопасный метод вместо getSingle

        if (task == null) {
          throw DataException("Task with id $id not found");
        }

        await (_db.update(_db.taskEntity)..where((t) => t.taskId.equals(id))).write(
          TaskEntityCompanion(taskIsCompleted: Value(!task.taskIsCompleted)),
        );
      });
    } on DataException catch (e) {
      throw DataException("Toggle failed: ${e.message}");
    }
  }
}

// TODO move to mappers (create it)
extension on TaskEntityData {
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
  );
}
