import 'package:collab_tasks/features/tasks/data/local/db/entities/task_entity.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_subtask.dart';
import 'package:collab_tasks/features/working_groups/data/local/db/entities/working_group_entities.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [TaskEntity, WorkingGroupsTable, GroupParticipantsTable, GroupTasksTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(taskEntity, taskEntity.taskPriority);
      }

      if (from < 3) {
        await m.addColumn(taskEntity, taskEntity.taskCreatedAt);

        // populate old records, taskPriority in task_entity had default values
        await customStatement('UPDATE task_entity SET task_created_at = ?', [
          DateTime.now().millisecondsSinceEpoch,
        ]);
      }

      if (from < 4) {
        // Add taskTitle column with default value for existing records
        await customStatement(
          'ALTER TABLE task_entity ADD COLUMN task_title TEXT NOT NULL DEFAULT ""',
        );
      }

      if (from < 5) {
        await m.addColumn(taskEntity, taskEntity.taskIsCompleted);
      }

      if (from < 6) {
        await m.addColumn(taskEntity, taskEntity.taskIsPinned);
      }

      if (from < 7) {
        await m.addColumn(taskEntity, taskEntity.taskDeadline);
      }

      if (from < 8) {
        await m.addColumn(taskEntity, taskEntity.taskSubtasks);
      }

      if (from < 9) {
        await m.addColumn(taskEntity, taskEntity.taskUpdatedAt);
      }

      if (from < 10) {
        await m.addColumn(taskEntity, taskEntity.taskOwnerId);
      }

      if (from < 11) {
        await transaction(() async {
          await customStatement('PRAGMA foreign_keys=OFF;');
          await customStatement('''
            CREATE TABLE IF NOT EXISTS task_entity_temp (
              task_id TEXT NOT NULL,
              task_owner_id TEXT NOT NULL DEFAULT '',
              task_title TEXT NOT NULL DEFAULT '',
              task_text TEXT NOT NULL,
              task_priority INTEGER NOT NULL DEFAULT 0,
              task_created_at INTEGER NOT NULL,
              task_attachments TEXT NOT NULL,
              task_subtasks TEXT NOT NULL DEFAULT '[]',
              task_is_completed INTEGER NOT NULL DEFAULT 0,
              task_deadline INTEGER,
              task_is_pinned INTEGER NOT NULL DEFAULT 0,
              task_updated_at INTEGER NOT NULL DEFAULT 0,
              PRIMARY KEY (task_owner_id, task_id)
            );
          ''');
          await customStatement('''
            INSERT INTO task_entity_temp (
              task_id, task_owner_id, task_title, task_text, task_priority,
              task_created_at, task_attachments, task_subtasks,
              task_is_completed, task_deadline, task_is_pinned, task_updated_at
            )
            SELECT 
              task_id, 
              COALESCE(task_owner_id, ''), 
              COALESCE(task_title, ''), 
              task_text, 
              task_priority,
              task_created_at, 
              task_attachments, 
              COALESCE(task_subtasks, '[]'),
              task_is_completed, 
              task_deadline, 
              task_is_pinned, 
              COALESCE(task_updated_at, 0)
            FROM task_entity;
          ''');
          await customStatement('DROP TABLE task_entity;');
          await customStatement('ALTER TABLE task_entity_temp RENAME TO task_entity;');
          await customStatement('PRAGMA foreign_keys=ON;');
        });
      }
      if (from < 13) {
        await m.addColumn(taskEntity, taskEntity.taskIsSynced);
      }
      if (from < 14) {
        await m.createTable(workingGroupsTable);
        await m.createTable(groupParticipantsTable);
        await m.createTable(groupTasksTable);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'task_manager_db',
      native: const DriftNativeOptions(
        shareAcrossIsolates: true,
        databaseDirectory: getApplicationSupportDirectory,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
    );
  }
}
