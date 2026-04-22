import 'package:drift/drift.dart';

import '../../domain/models/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../local/db/app_database.dart';

class TaskRepositoryImpl implements TaskRepository {
  final AppDatabase _db;

  TaskRepositoryImpl(this._db);

  Future<void> _upsertTask(Task task) {
    final companion = TaskEntityCompanion.insert(
      taskId: task.id,
      taskTitle: Value(task.title),
      taskCreatedAt: task.createdAt,
      taskText: task.text,
      taskPriority: Value(task.priority),
      taskAttachments: task.attachments,
      taskIsCompleted: Value(task.isCompleted),
    );

    return _db.into(_db.taskEntity).insert(companion, onConflict: DoUpdate((old) => companion));
  }

  @override
  Future<void> addTask(Task task) => _upsertTask(task);

  @override
  Future<void> updateTask(Task task) => _upsertTask(task);

  @override
  Future<void> deleteTask(String id) {
    return (_db.delete(_db.taskEntity)..where((t) => t.taskId.equals(id))).go();
  }

  @override
  Future<List<Task>> getTasks() async {
    final rows = await _db.select(_db.taskEntity).get();

    return rows
        .map(
          (row) => Task(
            id: row.taskId,
            createdAt: row.taskCreatedAt,
            title: row.taskTitle,
            text: row.taskText,
            priority: row.taskPriority,
            attachments: row.taskAttachments,
            isCompleted: row.taskIsCompleted,
          ),
        )
        .toList();
  }

  @override
  Future<void> toggleTask(String id) async {
    final task = await (_db.select(_db.taskEntity)..where((t) => t.taskId.equals(id))).getSingle();
    await (_db.update(_db.taskEntity)..where((t) => t.taskId.equals(id))).write(
      TaskEntityCompanion(taskIsCompleted: Value(!task.taskIsCompleted)),
    );
  }
}
