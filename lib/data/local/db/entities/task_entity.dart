import 'package:drift/drift.dart';

import '../../../../domain/models/task_attachment.dart';

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

class TaskEntity extends Table {
  TextColumn get taskId => text()();

  TextColumn get taskTitle => text().withDefault(const Constant(''))();

  TextColumn get taskText => text()();

  IntColumn get taskPriority => integer().withDefault(const Constant(0))();

  DateTimeColumn get taskCreatedAt => dateTime()();

  TextColumn get taskAttachments => text().map(const TaskAttachmentListConverter())();

  BoolColumn get taskIsCompleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {taskId};
}
