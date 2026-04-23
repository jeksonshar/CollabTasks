import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../../domain/models/task_attachment.dart';
import 'entities/task_entity.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [TaskEntity])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 7;

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
        await m.addColumn(taskEntity, taskEntity.taskDeadline);
      }

      if (from < 7) {
        await m.addColumn(taskEntity, taskEntity.taskIsPinned);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'task_manager_db',
      native: const DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
    );
  }
}
