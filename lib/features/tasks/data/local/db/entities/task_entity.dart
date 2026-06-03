import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_subtask.dart';
import 'package:drift/drift.dart';

class TaskAttachmentListConverter extends TypeConverter<List<TaskAttachment>, String> {
  const TaskAttachmentListConverter();

  @override
  List<TaskAttachment> fromSql(String fromDb) {
    return TaskAttachment.decodeList(fromDb);
  }

  @override
  String toSql(List<TaskAttachment> value) {
    return TaskAttachment.encodeList(value);
  }
}

class TaskSubtaskListConverter extends TypeConverter<List<TaskSubtask>, String> {
  const TaskSubtaskListConverter();

  @override
  List<TaskSubtask> fromSql(String fromDb) {
    if (fromDb.isEmpty) {
      return const [];
    }

    return TaskSubtaskCodec.decodeList(fromDb);
  }

  @override
  String toSql(List<TaskSubtask> value) {
    return TaskSubtaskCodec.encodeList(value);
  }
}

class TaskEntity extends Table {
  TextColumn get taskId => text()();

  TextColumn get taskOwnerId => text().withDefault(const Constant(''))();

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

  IntColumn get taskUpdatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {taskOwnerId, taskId};
}
