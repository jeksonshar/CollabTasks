// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TaskEntityTable extends TaskEntity with TableInfo<$TaskEntityTable, TaskEntityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;

  $TaskEntityTable(this.attachedDatabase, [this._alias]);

  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskOwnerIdMeta = const VerificationMeta('taskOwnerId');
  @override
  late final GeneratedColumn<String> taskOwnerId = GeneratedColumn<String>(
    'task_owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _taskTitleMeta = const VerificationMeta('taskTitle');
  @override
  late final GeneratedColumn<String> taskTitle = GeneratedColumn<String>(
    'task_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _taskTextMeta = const VerificationMeta('taskText');
  @override
  late final GeneratedColumn<String> taskText = GeneratedColumn<String>(
    'task_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskPriorityMeta = const VerificationMeta('taskPriority');
  @override
  late final GeneratedColumn<int> taskPriority = GeneratedColumn<int>(
    'task_priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taskCreatedAtMeta = const VerificationMeta('taskCreatedAt');
  @override
  late final GeneratedColumn<DateTime> taskCreatedAt = GeneratedColumn<DateTime>(
    'task_created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<TaskAttachment>, String> taskAttachments =
      GeneratedColumn<String>(
        'task_attachments',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<TaskAttachment>>($TaskEntityTable.$convertertaskAttachments);
  @override
  late final GeneratedColumnWithTypeConverter<List<TaskSubtask>, String> taskSubtasks =
      GeneratedColumn<String>(
        'task_subtasks',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<TaskSubtask>>($TaskEntityTable.$convertertaskSubtasks);
  static const VerificationMeta _taskIsCompletedMeta = const VerificationMeta('taskIsCompleted');
  @override
  late final GeneratedColumn<bool> taskIsCompleted = GeneratedColumn<bool>(
    'task_is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("task_is_completed" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _taskDeadlineMeta = const VerificationMeta('taskDeadline');
  @override
  late final GeneratedColumn<DateTime> taskDeadline = GeneratedColumn<DateTime>(
    'task_deadline',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskIsPinnedMeta = const VerificationMeta('taskIsPinned');
  @override
  late final GeneratedColumn<bool> taskIsPinned = GeneratedColumn<bool>(
    'task_is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("task_is_pinned" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _taskUpdatedAtMeta = const VerificationMeta('taskUpdatedAt');
  @override
  late final GeneratedColumn<int> taskUpdatedAt = GeneratedColumn<int>(
    'task_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );

  @override
  List<GeneratedColumn> get $columns => [
    taskId,
    taskOwnerId,
    taskTitle,
    taskText,
    taskPriority,
    taskCreatedAt,
    taskAttachments,
    taskSubtasks,
    taskIsCompleted,
    taskDeadline,
    taskIsPinned,
    taskUpdatedAt,
  ];

  @override
  String get aliasedName => _alias ?? actualTableName;

  @override
  String get actualTableName => $name;
  static const String $name = 'task_entity';

  @override
  VerificationContext validateIntegrity(
    Insertable<TaskEntityData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta, taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('task_owner_id')) {
      context.handle(
        _taskOwnerIdMeta,
        taskOwnerId.isAcceptableOrUnknown(data['task_owner_id']!, _taskOwnerIdMeta),
      );
    }
    if (data.containsKey('task_title')) {
      context.handle(
        _taskTitleMeta,
        taskTitle.isAcceptableOrUnknown(data['task_title']!, _taskTitleMeta),
      );
    }
    if (data.containsKey('task_text')) {
      context.handle(
        _taskTextMeta,
        taskText.isAcceptableOrUnknown(data['task_text']!, _taskTextMeta),
      );
    } else if (isInserting) {
      context.missing(_taskTextMeta);
    }
    if (data.containsKey('task_priority')) {
      context.handle(
        _taskPriorityMeta,
        taskPriority.isAcceptableOrUnknown(data['task_priority']!, _taskPriorityMeta),
      );
    }
    if (data.containsKey('task_created_at')) {
      context.handle(
        _taskCreatedAtMeta,
        taskCreatedAt.isAcceptableOrUnknown(data['task_created_at']!, _taskCreatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_taskCreatedAtMeta);
    }
    if (data.containsKey('task_is_completed')) {
      context.handle(
        _taskIsCompletedMeta,
        taskIsCompleted.isAcceptableOrUnknown(data['task_is_completed']!, _taskIsCompletedMeta),
      );
    }
    if (data.containsKey('task_deadline')) {
      context.handle(
        _taskDeadlineMeta,
        taskDeadline.isAcceptableOrUnknown(data['task_deadline']!, _taskDeadlineMeta),
      );
    }
    if (data.containsKey('task_is_pinned')) {
      context.handle(
        _taskIsPinnedMeta,
        taskIsPinned.isAcceptableOrUnknown(data['task_is_pinned']!, _taskIsPinnedMeta),
      );
    }
    if (data.containsKey('task_updated_at')) {
      context.handle(
        _taskUpdatedAtMeta,
        taskUpdatedAt.isAcceptableOrUnknown(data['task_updated_at']!, _taskUpdatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskOwnerId, taskId};

  @override
  TaskEntityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskEntityData(
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      taskOwnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_owner_id'],
      )!,
      taskTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_title'],
      )!,
      taskText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_text'],
      )!,
      taskPriority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_priority'],
      )!,
      taskCreatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}task_created_at'],
      )!,
      taskAttachments: $TaskEntityTable.$convertertaskAttachments.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}task_attachments'],
        )!,
      ),
      taskSubtasks: $TaskEntityTable.$convertertaskSubtasks.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}task_subtasks'],
        )!,
      ),
      taskIsCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}task_is_completed'],
      )!,
      taskDeadline: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}task_deadline'],
      ),
      taskIsPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}task_is_pinned'],
      )!,
      taskUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_updated_at'],
      )!,
    );
  }

  @override
  $TaskEntityTable createAlias(String alias) {
    return $TaskEntityTable(attachedDatabase, alias);
  }

  static TypeConverter<List<TaskAttachment>, String> $convertertaskAttachments =
      const TaskAttachmentListConverter();
  static TypeConverter<List<TaskSubtask>, String> $convertertaskSubtasks =
      const TaskSubtaskListConverter();
}

class TaskEntityData extends DataClass implements Insertable<TaskEntityData> {
  final String taskId;
  final String taskOwnerId;
  final String taskTitle;
  final String taskText;
  final int taskPriority;
  final DateTime taskCreatedAt;
  final List<TaskAttachment> taskAttachments;
  final List<TaskSubtask> taskSubtasks;
  final bool taskIsCompleted;
  final DateTime? taskDeadline;
  final bool taskIsPinned;
  final int taskUpdatedAt;

  const TaskEntityData({
    required this.taskId,
    required this.taskOwnerId,
    required this.taskTitle,
    required this.taskText,
    required this.taskPriority,
    required this.taskCreatedAt,
    required this.taskAttachments,
    required this.taskSubtasks,
    required this.taskIsCompleted,
    this.taskDeadline,
    required this.taskIsPinned,
    required this.taskUpdatedAt,
  });

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['task_owner_id'] = Variable<String>(taskOwnerId);
    map['task_title'] = Variable<String>(taskTitle);
    map['task_text'] = Variable<String>(taskText);
    map['task_priority'] = Variable<int>(taskPriority);
    map['task_created_at'] = Variable<DateTime>(taskCreatedAt);
    {
      map['task_attachments'] = Variable<String>(
        $TaskEntityTable.$convertertaskAttachments.toSql(taskAttachments),
      );
    }
    {
      map['task_subtasks'] = Variable<String>(
        $TaskEntityTable.$convertertaskSubtasks.toSql(taskSubtasks),
      );
    }
    map['task_is_completed'] = Variable<bool>(taskIsCompleted);
    if (!nullToAbsent || taskDeadline != null) {
      map['task_deadline'] = Variable<DateTime>(taskDeadline);
    }
    map['task_is_pinned'] = Variable<bool>(taskIsPinned);
    map['task_updated_at'] = Variable<int>(taskUpdatedAt);
    return map;
  }

  TaskEntityCompanion toCompanion(bool nullToAbsent) {
    return TaskEntityCompanion(
      taskId: Value(taskId),
      taskOwnerId: Value(taskOwnerId),
      taskTitle: Value(taskTitle),
      taskText: Value(taskText),
      taskPriority: Value(taskPriority),
      taskCreatedAt: Value(taskCreatedAt),
      taskAttachments: Value(taskAttachments),
      taskSubtasks: Value(taskSubtasks),
      taskIsCompleted: Value(taskIsCompleted),
      taskDeadline: taskDeadline == null && nullToAbsent
          ? const Value.absent()
          : Value(taskDeadline),
      taskIsPinned: Value(taskIsPinned),
      taskUpdatedAt: Value(taskUpdatedAt),
    );
  }

  factory TaskEntityData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskEntityData(
      taskId: serializer.fromJson<String>(json['taskId']),
      taskOwnerId: serializer.fromJson<String>(json['taskOwnerId']),
      taskTitle: serializer.fromJson<String>(json['taskTitle']),
      taskText: serializer.fromJson<String>(json['taskText']),
      taskPriority: serializer.fromJson<int>(json['taskPriority']),
      taskCreatedAt: serializer.fromJson<DateTime>(json['taskCreatedAt']),
      taskAttachments: serializer.fromJson<List<TaskAttachment>>(json['taskAttachments']),
      taskSubtasks: serializer.fromJson<List<TaskSubtask>>(json['taskSubtasks']),
      taskIsCompleted: serializer.fromJson<bool>(json['taskIsCompleted']),
      taskDeadline: serializer.fromJson<DateTime?>(json['taskDeadline']),
      taskIsPinned: serializer.fromJson<bool>(json['taskIsPinned']),
      taskUpdatedAt: serializer.fromJson<int>(json['taskUpdatedAt']),
    );
  }

  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskId': serializer.toJson<String>(taskId),
      'taskOwnerId': serializer.toJson<String>(taskOwnerId),
      'taskTitle': serializer.toJson<String>(taskTitle),
      'taskText': serializer.toJson<String>(taskText),
      'taskPriority': serializer.toJson<int>(taskPriority),
      'taskCreatedAt': serializer.toJson<DateTime>(taskCreatedAt),
      'taskAttachments': serializer.toJson<List<TaskAttachment>>(taskAttachments),
      'taskSubtasks': serializer.toJson<List<TaskSubtask>>(taskSubtasks),
      'taskIsCompleted': serializer.toJson<bool>(taskIsCompleted),
      'taskDeadline': serializer.toJson<DateTime?>(taskDeadline),
      'taskIsPinned': serializer.toJson<bool>(taskIsPinned),
      'taskUpdatedAt': serializer.toJson<int>(taskUpdatedAt),
    };
  }

  TaskEntityData copyWith({
    String? taskId,
    String? taskOwnerId,
    String? taskTitle,
    String? taskText,
    int? taskPriority,
    DateTime? taskCreatedAt,
    List<TaskAttachment>? taskAttachments,
    List<TaskSubtask>? taskSubtasks,
    bool? taskIsCompleted,
    Value<DateTime?> taskDeadline = const Value.absent(),
    bool? taskIsPinned,
    int? taskUpdatedAt,
  }) => TaskEntityData(
    taskId: taskId ?? this.taskId,
    taskOwnerId: taskOwnerId ?? this.taskOwnerId,
    taskTitle: taskTitle ?? this.taskTitle,
    taskText: taskText ?? this.taskText,
    taskPriority: taskPriority ?? this.taskPriority,
    taskCreatedAt: taskCreatedAt ?? this.taskCreatedAt,
    taskAttachments: taskAttachments ?? this.taskAttachments,
    taskSubtasks: taskSubtasks ?? this.taskSubtasks,
    taskIsCompleted: taskIsCompleted ?? this.taskIsCompleted,
    taskDeadline: taskDeadline.present ? taskDeadline.value : this.taskDeadline,
    taskIsPinned: taskIsPinned ?? this.taskIsPinned,
    taskUpdatedAt: taskUpdatedAt ?? this.taskUpdatedAt,
  );

  TaskEntityData copyWithCompanion(TaskEntityCompanion data) {
    return TaskEntityData(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      taskOwnerId: data.taskOwnerId.present ? data.taskOwnerId.value : this.taskOwnerId,
      taskTitle: data.taskTitle.present ? data.taskTitle.value : this.taskTitle,
      taskText: data.taskText.present ? data.taskText.value : this.taskText,
      taskPriority: data.taskPriority.present ? data.taskPriority.value : this.taskPriority,
      taskCreatedAt: data.taskCreatedAt.present ? data.taskCreatedAt.value : this.taskCreatedAt,
      taskAttachments: data.taskAttachments.present
          ? data.taskAttachments.value
          : this.taskAttachments,
      taskSubtasks: data.taskSubtasks.present ? data.taskSubtasks.value : this.taskSubtasks,
      taskIsCompleted: data.taskIsCompleted.present
          ? data.taskIsCompleted.value
          : this.taskIsCompleted,
      taskDeadline: data.taskDeadline.present ? data.taskDeadline.value : this.taskDeadline,
      taskIsPinned: data.taskIsPinned.present ? data.taskIsPinned.value : this.taskIsPinned,
      taskUpdatedAt: data.taskUpdatedAt.present ? data.taskUpdatedAt.value : this.taskUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskEntityData(')
          ..write('taskId: $taskId, ')
          ..write('taskOwnerId: $taskOwnerId, ')
          ..write('taskTitle: $taskTitle, ')
          ..write('taskText: $taskText, ')
          ..write('taskPriority: $taskPriority, ')
          ..write('taskCreatedAt: $taskCreatedAt, ')
          ..write('taskAttachments: $taskAttachments, ')
          ..write('taskSubtasks: $taskSubtasks, ')
          ..write('taskIsCompleted: $taskIsCompleted, ')
          ..write('taskDeadline: $taskDeadline, ')
          ..write('taskIsPinned: $taskIsPinned, ')
          ..write('taskUpdatedAt: $taskUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    taskId,
    taskOwnerId,
    taskTitle,
    taskText,
    taskPriority,
    taskCreatedAt,
    taskAttachments,
    taskSubtasks,
    taskIsCompleted,
    taskDeadline,
    taskIsPinned,
    taskUpdatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskEntityData &&
          other.taskId == this.taskId &&
          other.taskOwnerId == this.taskOwnerId &&
          other.taskTitle == this.taskTitle &&
          other.taskText == this.taskText &&
          other.taskPriority == this.taskPriority &&
          other.taskCreatedAt == this.taskCreatedAt &&
          other.taskAttachments == this.taskAttachments &&
          other.taskSubtasks == this.taskSubtasks &&
          other.taskIsCompleted == this.taskIsCompleted &&
          other.taskDeadline == this.taskDeadline &&
          other.taskIsPinned == this.taskIsPinned &&
          other.taskUpdatedAt == this.taskUpdatedAt);
}

class TaskEntityCompanion extends UpdateCompanion<TaskEntityData> {
  final Value<String> taskId;
  final Value<String> taskOwnerId;
  final Value<String> taskTitle;
  final Value<String> taskText;
  final Value<int> taskPriority;
  final Value<DateTime> taskCreatedAt;
  final Value<List<TaskAttachment>> taskAttachments;
  final Value<List<TaskSubtask>> taskSubtasks;
  final Value<bool> taskIsCompleted;
  final Value<DateTime?> taskDeadline;
  final Value<bool> taskIsPinned;
  final Value<int> taskUpdatedAt;
  final Value<int> rowid;

  const TaskEntityCompanion({
    this.taskId = const Value.absent(),
    this.taskOwnerId = const Value.absent(),
    this.taskTitle = const Value.absent(),
    this.taskText = const Value.absent(),
    this.taskPriority = const Value.absent(),
    this.taskCreatedAt = const Value.absent(),
    this.taskAttachments = const Value.absent(),
    this.taskSubtasks = const Value.absent(),
    this.taskIsCompleted = const Value.absent(),
    this.taskDeadline = const Value.absent(),
    this.taskIsPinned = const Value.absent(),
    this.taskUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });

  TaskEntityCompanion.insert({
    required String taskId,
    this.taskOwnerId = const Value.absent(),
    this.taskTitle = const Value.absent(),
    required String taskText,
    this.taskPriority = const Value.absent(),
    required DateTime taskCreatedAt,
    required List<TaskAttachment> taskAttachments,
    this.taskSubtasks = const Value.absent(),
    this.taskIsCompleted = const Value.absent(),
    this.taskDeadline = const Value.absent(),
    this.taskIsPinned = const Value.absent(),
    this.taskUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId),
       taskText = Value(taskText),
       taskCreatedAt = Value(taskCreatedAt),
       taskAttachments = Value(taskAttachments);

  static Insertable<TaskEntityData> custom({
    Expression<String>? taskId,
    Expression<String>? taskOwnerId,
    Expression<String>? taskTitle,
    Expression<String>? taskText,
    Expression<int>? taskPriority,
    Expression<DateTime>? taskCreatedAt,
    Expression<String>? taskAttachments,
    Expression<String>? taskSubtasks,
    Expression<bool>? taskIsCompleted,
    Expression<DateTime>? taskDeadline,
    Expression<bool>? taskIsPinned,
    Expression<int>? taskUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (taskOwnerId != null) 'task_owner_id': taskOwnerId,
      if (taskTitle != null) 'task_title': taskTitle,
      if (taskText != null) 'task_text': taskText,
      if (taskPriority != null) 'task_priority': taskPriority,
      if (taskCreatedAt != null) 'task_created_at': taskCreatedAt,
      if (taskAttachments != null) 'task_attachments': taskAttachments,
      if (taskSubtasks != null) 'task_subtasks': taskSubtasks,
      if (taskIsCompleted != null) 'task_is_completed': taskIsCompleted,
      if (taskDeadline != null) 'task_deadline': taskDeadline,
      if (taskIsPinned != null) 'task_is_pinned': taskIsPinned,
      if (taskUpdatedAt != null) 'task_updated_at': taskUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskEntityCompanion copyWith({
    Value<String>? taskId,
    Value<String>? taskOwnerId,
    Value<String>? taskTitle,
    Value<String>? taskText,
    Value<int>? taskPriority,
    Value<DateTime>? taskCreatedAt,
    Value<List<TaskAttachment>>? taskAttachments,
    Value<List<TaskSubtask>>? taskSubtasks,
    Value<bool>? taskIsCompleted,
    Value<DateTime?>? taskDeadline,
    Value<bool>? taskIsPinned,
    Value<int>? taskUpdatedAt,
    Value<int>? rowid,
  }) {
    return TaskEntityCompanion(
      taskId: taskId ?? this.taskId,
      taskOwnerId: taskOwnerId ?? this.taskOwnerId,
      taskTitle: taskTitle ?? this.taskTitle,
      taskText: taskText ?? this.taskText,
      taskPriority: taskPriority ?? this.taskPriority,
      taskCreatedAt: taskCreatedAt ?? this.taskCreatedAt,
      taskAttachments: taskAttachments ?? this.taskAttachments,
      taskSubtasks: taskSubtasks ?? this.taskSubtasks,
      taskIsCompleted: taskIsCompleted ?? this.taskIsCompleted,
      taskDeadline: taskDeadline ?? this.taskDeadline,
      taskIsPinned: taskIsPinned ?? this.taskIsPinned,
      taskUpdatedAt: taskUpdatedAt ?? this.taskUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (taskOwnerId.present) {
      map['task_owner_id'] = Variable<String>(taskOwnerId.value);
    }
    if (taskTitle.present) {
      map['task_title'] = Variable<String>(taskTitle.value);
    }
    if (taskText.present) {
      map['task_text'] = Variable<String>(taskText.value);
    }
    if (taskPriority.present) {
      map['task_priority'] = Variable<int>(taskPriority.value);
    }
    if (taskCreatedAt.present) {
      map['task_created_at'] = Variable<DateTime>(taskCreatedAt.value);
    }
    if (taskAttachments.present) {
      map['task_attachments'] = Variable<String>(
        $TaskEntityTable.$convertertaskAttachments.toSql(taskAttachments.value),
      );
    }
    if (taskSubtasks.present) {
      map['task_subtasks'] = Variable<String>(
        $TaskEntityTable.$convertertaskSubtasks.toSql(taskSubtasks.value),
      );
    }
    if (taskIsCompleted.present) {
      map['task_is_completed'] = Variable<bool>(taskIsCompleted.value);
    }
    if (taskDeadline.present) {
      map['task_deadline'] = Variable<DateTime>(taskDeadline.value);
    }
    if (taskIsPinned.present) {
      map['task_is_pinned'] = Variable<bool>(taskIsPinned.value);
    }
    if (taskUpdatedAt.present) {
      map['task_updated_at'] = Variable<int>(taskUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskEntityCompanion(')
          ..write('taskId: $taskId, ')
          ..write('taskOwnerId: $taskOwnerId, ')
          ..write('taskTitle: $taskTitle, ')
          ..write('taskText: $taskText, ')
          ..write('taskPriority: $taskPriority, ')
          ..write('taskCreatedAt: $taskCreatedAt, ')
          ..write('taskAttachments: $taskAttachments, ')
          ..write('taskSubtasks: $taskSubtasks, ')
          ..write('taskIsCompleted: $taskIsCompleted, ')
          ..write('taskDeadline: $taskDeadline, ')
          ..write('taskIsPinned: $taskIsPinned, ')
          ..write('taskUpdatedAt: $taskUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);

  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TaskEntityTable taskEntity = $TaskEntityTable(this);

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [taskEntity];
}

typedef $$TaskEntityTableCreateCompanionBuilder =
    TaskEntityCompanion Function({
      required String taskId,
      Value<String> taskOwnerId,
      Value<String> taskTitle,
      required String taskText,
      Value<int> taskPriority,
      required DateTime taskCreatedAt,
      required List<TaskAttachment> taskAttachments,
      Value<List<TaskSubtask>> taskSubtasks,
      Value<bool> taskIsCompleted,
      Value<DateTime?> taskDeadline,
      Value<bool> taskIsPinned,
      Value<int> taskUpdatedAt,
      Value<int> rowid,
    });
typedef $$TaskEntityTableUpdateCompanionBuilder =
    TaskEntityCompanion Function({
      Value<String> taskId,
      Value<String> taskOwnerId,
      Value<String> taskTitle,
      Value<String> taskText,
      Value<int> taskPriority,
      Value<DateTime> taskCreatedAt,
      Value<List<TaskAttachment>> taskAttachments,
      Value<List<TaskSubtask>> taskSubtasks,
      Value<bool> taskIsCompleted,
      Value<DateTime?> taskDeadline,
      Value<bool> taskIsPinned,
      Value<int> taskUpdatedAt,
      Value<int> rowid,
    });

class $$TaskEntityTableFilterComposer extends Composer<_$AppDatabase, $TaskEntityTable> {
  $$TaskEntityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });

  ColumnFilters<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taskOwnerId =>
      $composableBuilder(column: $table.taskOwnerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taskTitle =>
      $composableBuilder(column: $table.taskTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taskText =>
      $composableBuilder(column: $table.taskText, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get taskPriority =>
      $composableBuilder(column: $table.taskPriority, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get taskCreatedAt =>
      $composableBuilder(column: $table.taskCreatedAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<TaskAttachment>, List<TaskAttachment>, String>
  get taskAttachments => $composableBuilder(
    column: $table.taskAttachments,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<TaskSubtask>, List<TaskSubtask>, String> get taskSubtasks =>
      $composableBuilder(
        column: $table.taskSubtasks,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get taskIsCompleted => $composableBuilder(
    column: $table.taskIsCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get taskDeadline =>
      $composableBuilder(column: $table.taskDeadline, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get taskIsPinned =>
      $composableBuilder(column: $table.taskIsPinned, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get taskUpdatedAt =>
      $composableBuilder(column: $table.taskUpdatedAt, builder: (column) => ColumnFilters(column));
}

class $$TaskEntityTableOrderingComposer extends Composer<_$AppDatabase, $TaskEntityTable> {
  $$TaskEntityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });

  ColumnOrderings<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taskOwnerId =>
      $composableBuilder(column: $table.taskOwnerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taskTitle =>
      $composableBuilder(column: $table.taskTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taskText =>
      $composableBuilder(column: $table.taskText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get taskPriority =>
      $composableBuilder(column: $table.taskPriority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get taskCreatedAt => $composableBuilder(
    column: $table.taskCreatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskAttachments => $composableBuilder(
    column: $table.taskAttachments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskSubtasks =>
      $composableBuilder(column: $table.taskSubtasks, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get taskIsCompleted => $composableBuilder(
    column: $table.taskIsCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get taskDeadline =>
      $composableBuilder(column: $table.taskDeadline, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get taskIsPinned =>
      $composableBuilder(column: $table.taskIsPinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get taskUpdatedAt => $composableBuilder(
    column: $table.taskUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskEntityTableAnnotationComposer extends Composer<_$AppDatabase, $TaskEntityTable> {
  $$TaskEntityTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get taskOwnerId =>
      $composableBuilder(column: $table.taskOwnerId, builder: (column) => column);

  GeneratedColumn<String> get taskTitle =>
      $composableBuilder(column: $table.taskTitle, builder: (column) => column);

  GeneratedColumn<String> get taskText =>
      $composableBuilder(column: $table.taskText, builder: (column) => column);

  GeneratedColumn<int> get taskPriority =>
      $composableBuilder(column: $table.taskPriority, builder: (column) => column);

  GeneratedColumn<DateTime> get taskCreatedAt =>
      $composableBuilder(column: $table.taskCreatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<TaskAttachment>, String> get taskAttachments =>
      $composableBuilder(column: $table.taskAttachments, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<TaskSubtask>, String> get taskSubtasks =>
      $composableBuilder(column: $table.taskSubtasks, builder: (column) => column);

  GeneratedColumn<bool> get taskIsCompleted =>
      $composableBuilder(column: $table.taskIsCompleted, builder: (column) => column);

  GeneratedColumn<DateTime> get taskDeadline =>
      $composableBuilder(column: $table.taskDeadline, builder: (column) => column);

  GeneratedColumn<bool> get taskIsPinned =>
      $composableBuilder(column: $table.taskIsPinned, builder: (column) => column);

  GeneratedColumn<int> get taskUpdatedAt =>
      $composableBuilder(column: $table.taskUpdatedAt, builder: (column) => column);
}

class $$TaskEntityTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskEntityTable,
          TaskEntityData,
          $$TaskEntityTableFilterComposer,
          $$TaskEntityTableOrderingComposer,
          $$TaskEntityTableAnnotationComposer,
          $$TaskEntityTableCreateCompanionBuilder,
          $$TaskEntityTableUpdateCompanionBuilder,
          (TaskEntityData, BaseReferences<_$AppDatabase, $TaskEntityTable, TaskEntityData>),
          TaskEntityData,
          PrefetchHooks Function()
        > {
  $$TaskEntityTableTableManager(_$AppDatabase db, $TaskEntityTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TaskEntityTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TaskEntityTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskEntityTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> taskId = const Value.absent(),
                Value<String> taskOwnerId = const Value.absent(),
                Value<String> taskTitle = const Value.absent(),
                Value<String> taskText = const Value.absent(),
                Value<int> taskPriority = const Value.absent(),
                Value<DateTime> taskCreatedAt = const Value.absent(),
                Value<List<TaskAttachment>> taskAttachments = const Value.absent(),
                Value<List<TaskSubtask>> taskSubtasks = const Value.absent(),
                Value<bool> taskIsCompleted = const Value.absent(),
                Value<DateTime?> taskDeadline = const Value.absent(),
                Value<bool> taskIsPinned = const Value.absent(),
                Value<int> taskUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskEntityCompanion(
                taskId: taskId,
                taskOwnerId: taskOwnerId,
                taskTitle: taskTitle,
                taskText: taskText,
                taskPriority: taskPriority,
                taskCreatedAt: taskCreatedAt,
                taskAttachments: taskAttachments,
                taskSubtasks: taskSubtasks,
                taskIsCompleted: taskIsCompleted,
                taskDeadline: taskDeadline,
                taskIsPinned: taskIsPinned,
                taskUpdatedAt: taskUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskId,
                Value<String> taskOwnerId = const Value.absent(),
                Value<String> taskTitle = const Value.absent(),
                required String taskText,
                Value<int> taskPriority = const Value.absent(),
                required DateTime taskCreatedAt,
                required List<TaskAttachment> taskAttachments,
                Value<List<TaskSubtask>> taskSubtasks = const Value.absent(),
                Value<bool> taskIsCompleted = const Value.absent(),
                Value<DateTime?> taskDeadline = const Value.absent(),
                Value<bool> taskIsPinned = const Value.absent(),
                Value<int> taskUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskEntityCompanion.insert(
                taskId: taskId,
                taskOwnerId: taskOwnerId,
                taskTitle: taskTitle,
                taskText: taskText,
                taskPriority: taskPriority,
                taskCreatedAt: taskCreatedAt,
                taskAttachments: taskAttachments,
                taskSubtasks: taskSubtasks,
                taskIsCompleted: taskIsCompleted,
                taskDeadline: taskDeadline,
                taskIsPinned: taskIsPinned,
                taskUpdatedAt: taskUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), BaseReferences(db, table, e))).toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskEntityTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskEntityTable,
      TaskEntityData,
      $$TaskEntityTableFilterComposer,
      $$TaskEntityTableOrderingComposer,
      $$TaskEntityTableAnnotationComposer,
      $$TaskEntityTableCreateCompanionBuilder,
      $$TaskEntityTableUpdateCompanionBuilder,
      (TaskEntityData, BaseReferences<_$AppDatabase, $TaskEntityTable, TaskEntityData>),
      TaskEntityData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;

  $AppDatabaseManager(this._db);

  $$TaskEntityTableTableManager get taskEntity =>
      $$TaskEntityTableTableManager(_db, _db.taskEntity);
}
