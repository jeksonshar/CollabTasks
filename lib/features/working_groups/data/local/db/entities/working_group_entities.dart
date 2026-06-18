import 'package:collab_tasks/features/tasks/data/local/db/entities/task_entity.dart';
import 'package:drift/drift.dart';

class WorkingGroupsTable extends Table {
  TextColumn get id => text()();

  TextColumn get title => text()();

  TextColumn get description => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt => dateTime()();

  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class GroupParticipantsTable extends Table {
  TextColumn get id => text()();

  TextColumn get groupId =>
      text().references(WorkingGroupsTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get userId => text()();

  TextColumn get name => text()();

  TextColumn get avatarUrl => text().nullable()();

  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class GroupTasksTable extends Table {
  TextColumn get taskId => text()();

  TextColumn get groupId =>
      text().references(WorkingGroupsTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get taskTitle => text().withDefault(const Constant(''))();

  TextColumn get taskText => text()();

  IntColumn get taskPriority => integer().withDefault(const Constant(0))();

  DateTimeColumn get taskCreatedAt => dateTime()();

  TextColumn get taskAttachments => text().map(const TaskAttachmentListConverter())();

  TextColumn get taskSubtasks =>
      text().withDefault(const Constant('[]')).map(const TaskSubtaskListConverter())();

  BoolColumn get taskIsCompleted => boolean().withDefault(const Constant(false))();

  DateTimeColumn get taskDeadline => dateTime().nullable()();

  BoolColumn get taskIsPinned => boolean().withDefault(const Constant(false))();

  BoolColumn get taskIsSynced => boolean().withDefault(const Constant(false))();

  TextColumn get assignedUserId =>
      text().nullable().references(GroupParticipantsTable, #id, onDelete: KeyAction.setNull)();

  IntColumn get taskUpdatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {groupId, taskId};
}
