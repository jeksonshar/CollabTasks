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
  static const VerificationMeta _taskIsSyncedMeta = const VerificationMeta('taskIsSynced');
  @override
  late final GeneratedColumn<bool> taskIsSynced = GeneratedColumn<bool>(
    'task_is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("task_is_synced" IN (0, 1))'),
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
    taskIsSynced,
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
    if (data.containsKey('task_is_synced')) {
      context.handle(
        _taskIsSyncedMeta,
        taskIsSynced.isAcceptableOrUnknown(data['task_is_synced']!, _taskIsSyncedMeta),
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
      taskIsSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}task_is_synced'],
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
  final bool taskIsSynced;
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
    required this.taskIsSynced,
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
    map['task_is_synced'] = Variable<bool>(taskIsSynced);
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
      taskIsSynced: Value(taskIsSynced),
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
      taskIsSynced: serializer.fromJson<bool>(json['taskIsSynced']),
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
      'taskIsSynced': serializer.toJson<bool>(taskIsSynced),
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
    bool? taskIsSynced,
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
    taskIsSynced: taskIsSynced ?? this.taskIsSynced,
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
      taskIsSynced: data.taskIsSynced.present ? data.taskIsSynced.value : this.taskIsSynced,
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
          ..write('taskIsSynced: $taskIsSynced, ')
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
    taskIsSynced,
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
          other.taskIsSynced == this.taskIsSynced &&
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
  final Value<bool> taskIsSynced;
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
    this.taskIsSynced = const Value.absent(),
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
    this.taskIsSynced = const Value.absent(),
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
    Expression<bool>? taskIsSynced,
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
      if (taskIsSynced != null) 'task_is_synced': taskIsSynced,
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
    Value<bool>? taskIsSynced,
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
      taskIsSynced: taskIsSynced ?? this.taskIsSynced,
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
    if (taskIsSynced.present) {
      map['task_is_synced'] = Variable<bool>(taskIsSynced.value);
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
          ..write('taskIsSynced: $taskIsSynced, ')
          ..write('taskUpdatedAt: $taskUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkingGroupsTableTable extends WorkingGroupsTable
    with TableInfo<$WorkingGroupsTableTable, WorkingGroupsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;

  $WorkingGroupsTableTable(this.attachedDatabase, [this._alias]);

  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );

  @override
  List<GeneratedColumn> get $columns => [id, title, description, createdAt, updatedAt];

  @override
  String get aliasedName => _alias ?? actualTableName;

  @override
  String get actualTableName => $name;
  static const String $name = 'working_groups_table';

  @override
  VerificationContext validateIntegrity(
    Insertable<WorkingGroupsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(data['description']!, _descriptionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};

  @override
  WorkingGroupsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkingGroupsTableData(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WorkingGroupsTableTable createAlias(String alias) {
    return $WorkingGroupsTableTable(attachedDatabase, alias);
  }
}

class WorkingGroupsTableData extends DataClass implements Insertable<WorkingGroupsTableData> {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final int updatedAt;

  const WorkingGroupsTableData({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  WorkingGroupsTableCompanion toCompanion(bool nullToAbsent) {
    return WorkingGroupsTableCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WorkingGroupsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkingGroupsTableData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }

  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  WorkingGroupsTableData copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    int? updatedAt,
  }) => WorkingGroupsTableData(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  WorkingGroupsTableData copyWithCompanion(WorkingGroupsTableCompanion data) {
    return WorkingGroupsTableData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present ? data.description.value : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkingGroupsTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, description, createdAt, updatedAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkingGroupsTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WorkingGroupsTableCompanion extends UpdateCompanion<WorkingGroupsTableData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> description;
  final Value<DateTime> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;

  const WorkingGroupsTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });

  WorkingGroupsTableCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt);

  static Insertable<WorkingGroupsTableData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkingGroupsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? description,
    Value<DateTime>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return WorkingGroupsTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkingGroupsTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupParticipantsTableTable extends GroupParticipantsTable
    with TableInfo<$GroupParticipantsTableTable, GroupParticipantsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;

  $GroupParticipantsTableTable(this.attachedDatabase, [this._alias]);

  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES working_groups_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta('avatarUrl');
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );

  @override
  List<GeneratedColumn> get $columns => [id, groupId, userId, name, avatarUrl, updatedAt];

  @override
  String get aliasedName => _alias ?? actualTableName;

  @override
  String get actualTableName => $name;
  static const String $name = 'group_participants_table';

  @override
  VerificationContext validateIntegrity(
    Insertable<GroupParticipantsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta, groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta, userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};

  @override
  GroupParticipantsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupParticipantsTableData(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $GroupParticipantsTableTable createAlias(String alias) {
    return $GroupParticipantsTableTable(attachedDatabase, alias);
  }
}

class GroupParticipantsTableData extends DataClass
    implements Insertable<GroupParticipantsTableData> {
  final String id;
  final String groupId;
  final String userId;
  final String name;
  final String? avatarUrl;
  final int updatedAt;

  const GroupParticipantsTableData({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.updatedAt,
  });

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  GroupParticipantsTableCompanion toCompanion(bool nullToAbsent) {
    return GroupParticipantsTableCompanion(
      id: Value(id),
      groupId: Value(groupId),
      userId: Value(userId),
      name: Value(name),
      avatarUrl: avatarUrl == null && nullToAbsent ? const Value.absent() : Value(avatarUrl),
      updatedAt: Value(updatedAt),
    );
  }

  factory GroupParticipantsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupParticipantsTableData(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }

  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  GroupParticipantsTableData copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? name,
    Value<String?> avatarUrl = const Value.absent(),
    int? updatedAt,
  }) => GroupParticipantsTableData(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  GroupParticipantsTableData copyWithCompanion(GroupParticipantsTableCompanion data) {
    return GroupParticipantsTableData(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupParticipantsTableData(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, groupId, userId, name, avatarUrl, updatedAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupParticipantsTableData &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.avatarUrl == this.avatarUrl &&
          other.updatedAt == this.updatedAt);
}

class GroupParticipantsTableCompanion extends UpdateCompanion<GroupParticipantsTableData> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> userId;
  final Value<String> name;
  final Value<String?> avatarUrl;
  final Value<int> updatedAt;
  final Value<int> rowid;

  const GroupParticipantsTableCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });

  GroupParticipantsTableCompanion.insert({
    required String id,
    required String groupId,
    required String userId,
    required String name,
    this.avatarUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       userId = Value(userId),
       name = Value(name);

  static Insertable<GroupParticipantsTableData> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? avatarUrl,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupParticipantsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? userId,
    Value<String>? name,
    Value<String?>? avatarUrl,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return GroupParticipantsTableCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupParticipantsTableCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupTasksTableTable extends GroupTasksTable
    with TableInfo<$GroupTasksTableTable, GroupTasksTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;

  $GroupTasksTableTable(this.attachedDatabase, [this._alias]);

  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES working_groups_table (id) ON DELETE CASCADE',
    ),
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
      ).withConverter<List<TaskAttachment>>($GroupTasksTableTable.$convertertaskAttachments);
  @override
  late final GeneratedColumnWithTypeConverter<List<TaskSubtask>, String> taskSubtasks =
      GeneratedColumn<String>(
        'task_subtasks',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<TaskSubtask>>($GroupTasksTableTable.$convertertaskSubtasks);
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
  static const VerificationMeta _taskIsSyncedMeta = const VerificationMeta('taskIsSynced');
  @override
  late final GeneratedColumn<bool> taskIsSynced = GeneratedColumn<bool>(
    'task_is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("task_is_synced" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _assignedUserIdMeta = const VerificationMeta('assignedUserId');
  @override
  late final GeneratedColumn<String> assignedUserId = GeneratedColumn<String>(
    'assigned_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES group_participants_table (id) ON DELETE SET NULL',
    ),
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
    groupId,
    taskTitle,
    taskText,
    taskPriority,
    taskCreatedAt,
    taskAttachments,
    taskSubtasks,
    taskIsCompleted,
    taskDeadline,
    taskIsPinned,
    taskIsSynced,
    assignedUserId,
    taskUpdatedAt,
  ];

  @override
  String get aliasedName => _alias ?? actualTableName;

  @override
  String get actualTableName => $name;
  static const String $name = 'group_tasks_table';

  @override
  VerificationContext validateIntegrity(
    Insertable<GroupTasksTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta, taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta, groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
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
    if (data.containsKey('task_is_synced')) {
      context.handle(
        _taskIsSyncedMeta,
        taskIsSynced.isAcceptableOrUnknown(data['task_is_synced']!, _taskIsSyncedMeta),
      );
    }
    if (data.containsKey('assigned_user_id')) {
      context.handle(
        _assignedUserIdMeta,
        assignedUserId.isAcceptableOrUnknown(data['assigned_user_id']!, _assignedUserIdMeta),
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
  Set<GeneratedColumn> get $primaryKey => {groupId, taskId};

  @override
  GroupTasksTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupTasksTableData(
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
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
      taskAttachments: $GroupTasksTableTable.$convertertaskAttachments.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}task_attachments'],
        )!,
      ),
      taskSubtasks: $GroupTasksTableTable.$convertertaskSubtasks.fromSql(
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
      taskIsSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}task_is_synced'],
      )!,
      assignedUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assigned_user_id'],
      ),
      taskUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_updated_at'],
      )!,
    );
  }

  @override
  $GroupTasksTableTable createAlias(String alias) {
    return $GroupTasksTableTable(attachedDatabase, alias);
  }

  static TypeConverter<List<TaskAttachment>, String> $convertertaskAttachments =
      const TaskAttachmentListConverter();
  static TypeConverter<List<TaskSubtask>, String> $convertertaskSubtasks =
      const TaskSubtaskListConverter();
}

class GroupTasksTableData extends DataClass implements Insertable<GroupTasksTableData> {
  final String taskId;
  final String groupId;
  final String taskTitle;
  final String taskText;
  final int taskPriority;
  final DateTime taskCreatedAt;
  final List<TaskAttachment> taskAttachments;
  final List<TaskSubtask> taskSubtasks;
  final bool taskIsCompleted;
  final DateTime? taskDeadline;
  final bool taskIsPinned;
  final bool taskIsSynced;
  final String? assignedUserId;
  final int taskUpdatedAt;

  const GroupTasksTableData({
    required this.taskId,
    required this.groupId,
    required this.taskTitle,
    required this.taskText,
    required this.taskPriority,
    required this.taskCreatedAt,
    required this.taskAttachments,
    required this.taskSubtasks,
    required this.taskIsCompleted,
    this.taskDeadline,
    required this.taskIsPinned,
    required this.taskIsSynced,
    this.assignedUserId,
    required this.taskUpdatedAt,
  });

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['group_id'] = Variable<String>(groupId);
    map['task_title'] = Variable<String>(taskTitle);
    map['task_text'] = Variable<String>(taskText);
    map['task_priority'] = Variable<int>(taskPriority);
    map['task_created_at'] = Variable<DateTime>(taskCreatedAt);
    {
      map['task_attachments'] = Variable<String>(
        $GroupTasksTableTable.$convertertaskAttachments.toSql(taskAttachments),
      );
    }
    {
      map['task_subtasks'] = Variable<String>(
        $GroupTasksTableTable.$convertertaskSubtasks.toSql(taskSubtasks),
      );
    }
    map['task_is_completed'] = Variable<bool>(taskIsCompleted);
    if (!nullToAbsent || taskDeadline != null) {
      map['task_deadline'] = Variable<DateTime>(taskDeadline);
    }
    map['task_is_pinned'] = Variable<bool>(taskIsPinned);
    map['task_is_synced'] = Variable<bool>(taskIsSynced);
    if (!nullToAbsent || assignedUserId != null) {
      map['assigned_user_id'] = Variable<String>(assignedUserId);
    }
    map['task_updated_at'] = Variable<int>(taskUpdatedAt);
    return map;
  }

  GroupTasksTableCompanion toCompanion(bool nullToAbsent) {
    return GroupTasksTableCompanion(
      taskId: Value(taskId),
      groupId: Value(groupId),
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
      taskIsSynced: Value(taskIsSynced),
      assignedUserId: assignedUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedUserId),
      taskUpdatedAt: Value(taskUpdatedAt),
    );
  }

  factory GroupTasksTableData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupTasksTableData(
      taskId: serializer.fromJson<String>(json['taskId']),
      groupId: serializer.fromJson<String>(json['groupId']),
      taskTitle: serializer.fromJson<String>(json['taskTitle']),
      taskText: serializer.fromJson<String>(json['taskText']),
      taskPriority: serializer.fromJson<int>(json['taskPriority']),
      taskCreatedAt: serializer.fromJson<DateTime>(json['taskCreatedAt']),
      taskAttachments: serializer.fromJson<List<TaskAttachment>>(json['taskAttachments']),
      taskSubtasks: serializer.fromJson<List<TaskSubtask>>(json['taskSubtasks']),
      taskIsCompleted: serializer.fromJson<bool>(json['taskIsCompleted']),
      taskDeadline: serializer.fromJson<DateTime?>(json['taskDeadline']),
      taskIsPinned: serializer.fromJson<bool>(json['taskIsPinned']),
      taskIsSynced: serializer.fromJson<bool>(json['taskIsSynced']),
      assignedUserId: serializer.fromJson<String?>(json['assignedUserId']),
      taskUpdatedAt: serializer.fromJson<int>(json['taskUpdatedAt']),
    );
  }

  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskId': serializer.toJson<String>(taskId),
      'groupId': serializer.toJson<String>(groupId),
      'taskTitle': serializer.toJson<String>(taskTitle),
      'taskText': serializer.toJson<String>(taskText),
      'taskPriority': serializer.toJson<int>(taskPriority),
      'taskCreatedAt': serializer.toJson<DateTime>(taskCreatedAt),
      'taskAttachments': serializer.toJson<List<TaskAttachment>>(taskAttachments),
      'taskSubtasks': serializer.toJson<List<TaskSubtask>>(taskSubtasks),
      'taskIsCompleted': serializer.toJson<bool>(taskIsCompleted),
      'taskDeadline': serializer.toJson<DateTime?>(taskDeadline),
      'taskIsPinned': serializer.toJson<bool>(taskIsPinned),
      'taskIsSynced': serializer.toJson<bool>(taskIsSynced),
      'assignedUserId': serializer.toJson<String?>(assignedUserId),
      'taskUpdatedAt': serializer.toJson<int>(taskUpdatedAt),
    };
  }

  GroupTasksTableData copyWith({
    String? taskId,
    String? groupId,
    String? taskTitle,
    String? taskText,
    int? taskPriority,
    DateTime? taskCreatedAt,
    List<TaskAttachment>? taskAttachments,
    List<TaskSubtask>? taskSubtasks,
    bool? taskIsCompleted,
    Value<DateTime?> taskDeadline = const Value.absent(),
    bool? taskIsPinned,
    bool? taskIsSynced,
    Value<String?> assignedUserId = const Value.absent(),
    int? taskUpdatedAt,
  }) => GroupTasksTableData(
    taskId: taskId ?? this.taskId,
    groupId: groupId ?? this.groupId,
    taskTitle: taskTitle ?? this.taskTitle,
    taskText: taskText ?? this.taskText,
    taskPriority: taskPriority ?? this.taskPriority,
    taskCreatedAt: taskCreatedAt ?? this.taskCreatedAt,
    taskAttachments: taskAttachments ?? this.taskAttachments,
    taskSubtasks: taskSubtasks ?? this.taskSubtasks,
    taskIsCompleted: taskIsCompleted ?? this.taskIsCompleted,
    taskDeadline: taskDeadline.present ? taskDeadline.value : this.taskDeadline,
    taskIsPinned: taskIsPinned ?? this.taskIsPinned,
    taskIsSynced: taskIsSynced ?? this.taskIsSynced,
    assignedUserId: assignedUserId.present ? assignedUserId.value : this.assignedUserId,
    taskUpdatedAt: taskUpdatedAt ?? this.taskUpdatedAt,
  );

  GroupTasksTableData copyWithCompanion(GroupTasksTableCompanion data) {
    return GroupTasksTableData(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
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
      taskIsSynced: data.taskIsSynced.present ? data.taskIsSynced.value : this.taskIsSynced,
      assignedUserId: data.assignedUserId.present ? data.assignedUserId.value : this.assignedUserId,
      taskUpdatedAt: data.taskUpdatedAt.present ? data.taskUpdatedAt.value : this.taskUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupTasksTableData(')
          ..write('taskId: $taskId, ')
          ..write('groupId: $groupId, ')
          ..write('taskTitle: $taskTitle, ')
          ..write('taskText: $taskText, ')
          ..write('taskPriority: $taskPriority, ')
          ..write('taskCreatedAt: $taskCreatedAt, ')
          ..write('taskAttachments: $taskAttachments, ')
          ..write('taskSubtasks: $taskSubtasks, ')
          ..write('taskIsCompleted: $taskIsCompleted, ')
          ..write('taskDeadline: $taskDeadline, ')
          ..write('taskIsPinned: $taskIsPinned, ')
          ..write('taskIsSynced: $taskIsSynced, ')
          ..write('assignedUserId: $assignedUserId, ')
          ..write('taskUpdatedAt: $taskUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    taskId,
    groupId,
    taskTitle,
    taskText,
    taskPriority,
    taskCreatedAt,
    taskAttachments,
    taskSubtasks,
    taskIsCompleted,
    taskDeadline,
    taskIsPinned,
    taskIsSynced,
    assignedUserId,
    taskUpdatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupTasksTableData &&
          other.taskId == this.taskId &&
          other.groupId == this.groupId &&
          other.taskTitle == this.taskTitle &&
          other.taskText == this.taskText &&
          other.taskPriority == this.taskPriority &&
          other.taskCreatedAt == this.taskCreatedAt &&
          other.taskAttachments == this.taskAttachments &&
          other.taskSubtasks == this.taskSubtasks &&
          other.taskIsCompleted == this.taskIsCompleted &&
          other.taskDeadline == this.taskDeadline &&
          other.taskIsPinned == this.taskIsPinned &&
          other.taskIsSynced == this.taskIsSynced &&
          other.assignedUserId == this.assignedUserId &&
          other.taskUpdatedAt == this.taskUpdatedAt);
}

class GroupTasksTableCompanion extends UpdateCompanion<GroupTasksTableData> {
  final Value<String> taskId;
  final Value<String> groupId;
  final Value<String> taskTitle;
  final Value<String> taskText;
  final Value<int> taskPriority;
  final Value<DateTime> taskCreatedAt;
  final Value<List<TaskAttachment>> taskAttachments;
  final Value<List<TaskSubtask>> taskSubtasks;
  final Value<bool> taskIsCompleted;
  final Value<DateTime?> taskDeadline;
  final Value<bool> taskIsPinned;
  final Value<bool> taskIsSynced;
  final Value<String?> assignedUserId;
  final Value<int> taskUpdatedAt;
  final Value<int> rowid;

  const GroupTasksTableCompanion({
    this.taskId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.taskTitle = const Value.absent(),
    this.taskText = const Value.absent(),
    this.taskPriority = const Value.absent(),
    this.taskCreatedAt = const Value.absent(),
    this.taskAttachments = const Value.absent(),
    this.taskSubtasks = const Value.absent(),
    this.taskIsCompleted = const Value.absent(),
    this.taskDeadline = const Value.absent(),
    this.taskIsPinned = const Value.absent(),
    this.taskIsSynced = const Value.absent(),
    this.assignedUserId = const Value.absent(),
    this.taskUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });

  GroupTasksTableCompanion.insert({
    required String taskId,
    required String groupId,
    this.taskTitle = const Value.absent(),
    required String taskText,
    this.taskPriority = const Value.absent(),
    required DateTime taskCreatedAt,
    required List<TaskAttachment> taskAttachments,
    this.taskSubtasks = const Value.absent(),
    this.taskIsCompleted = const Value.absent(),
    this.taskDeadline = const Value.absent(),
    this.taskIsPinned = const Value.absent(),
    this.taskIsSynced = const Value.absent(),
    this.assignedUserId = const Value.absent(),
    this.taskUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId),
       groupId = Value(groupId),
       taskText = Value(taskText),
       taskCreatedAt = Value(taskCreatedAt),
       taskAttachments = Value(taskAttachments);

  static Insertable<GroupTasksTableData> custom({
    Expression<String>? taskId,
    Expression<String>? groupId,
    Expression<String>? taskTitle,
    Expression<String>? taskText,
    Expression<int>? taskPriority,
    Expression<DateTime>? taskCreatedAt,
    Expression<String>? taskAttachments,
    Expression<String>? taskSubtasks,
    Expression<bool>? taskIsCompleted,
    Expression<DateTime>? taskDeadline,
    Expression<bool>? taskIsPinned,
    Expression<bool>? taskIsSynced,
    Expression<String>? assignedUserId,
    Expression<int>? taskUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (groupId != null) 'group_id': groupId,
      if (taskTitle != null) 'task_title': taskTitle,
      if (taskText != null) 'task_text': taskText,
      if (taskPriority != null) 'task_priority': taskPriority,
      if (taskCreatedAt != null) 'task_created_at': taskCreatedAt,
      if (taskAttachments != null) 'task_attachments': taskAttachments,
      if (taskSubtasks != null) 'task_subtasks': taskSubtasks,
      if (taskIsCompleted != null) 'task_is_completed': taskIsCompleted,
      if (taskDeadline != null) 'task_deadline': taskDeadline,
      if (taskIsPinned != null) 'task_is_pinned': taskIsPinned,
      if (taskIsSynced != null) 'task_is_synced': taskIsSynced,
      if (assignedUserId != null) 'assigned_user_id': assignedUserId,
      if (taskUpdatedAt != null) 'task_updated_at': taskUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupTasksTableCompanion copyWith({
    Value<String>? taskId,
    Value<String>? groupId,
    Value<String>? taskTitle,
    Value<String>? taskText,
    Value<int>? taskPriority,
    Value<DateTime>? taskCreatedAt,
    Value<List<TaskAttachment>>? taskAttachments,
    Value<List<TaskSubtask>>? taskSubtasks,
    Value<bool>? taskIsCompleted,
    Value<DateTime?>? taskDeadline,
    Value<bool>? taskIsPinned,
    Value<bool>? taskIsSynced,
    Value<String?>? assignedUserId,
    Value<int>? taskUpdatedAt,
    Value<int>? rowid,
  }) {
    return GroupTasksTableCompanion(
      taskId: taskId ?? this.taskId,
      groupId: groupId ?? this.groupId,
      taskTitle: taskTitle ?? this.taskTitle,
      taskText: taskText ?? this.taskText,
      taskPriority: taskPriority ?? this.taskPriority,
      taskCreatedAt: taskCreatedAt ?? this.taskCreatedAt,
      taskAttachments: taskAttachments ?? this.taskAttachments,
      taskSubtasks: taskSubtasks ?? this.taskSubtasks,
      taskIsCompleted: taskIsCompleted ?? this.taskIsCompleted,
      taskDeadline: taskDeadline ?? this.taskDeadline,
      taskIsPinned: taskIsPinned ?? this.taskIsPinned,
      taskIsSynced: taskIsSynced ?? this.taskIsSynced,
      assignedUserId: assignedUserId ?? this.assignedUserId,
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
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
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
        $GroupTasksTableTable.$convertertaskAttachments.toSql(taskAttachments.value),
      );
    }
    if (taskSubtasks.present) {
      map['task_subtasks'] = Variable<String>(
        $GroupTasksTableTable.$convertertaskSubtasks.toSql(taskSubtasks.value),
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
    if (taskIsSynced.present) {
      map['task_is_synced'] = Variable<bool>(taskIsSynced.value);
    }
    if (assignedUserId.present) {
      map['assigned_user_id'] = Variable<String>(assignedUserId.value);
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
    return (StringBuffer('GroupTasksTableCompanion(')
          ..write('taskId: $taskId, ')
          ..write('groupId: $groupId, ')
          ..write('taskTitle: $taskTitle, ')
          ..write('taskText: $taskText, ')
          ..write('taskPriority: $taskPriority, ')
          ..write('taskCreatedAt: $taskCreatedAt, ')
          ..write('taskAttachments: $taskAttachments, ')
          ..write('taskSubtasks: $taskSubtasks, ')
          ..write('taskIsCompleted: $taskIsCompleted, ')
          ..write('taskDeadline: $taskDeadline, ')
          ..write('taskIsPinned: $taskIsPinned, ')
          ..write('taskIsSynced: $taskIsSynced, ')
          ..write('assignedUserId: $assignedUserId, ')
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
  late final $WorkingGroupsTableTable workingGroupsTable = $WorkingGroupsTableTable(this);
  late final $GroupParticipantsTableTable groupParticipantsTable = $GroupParticipantsTableTable(
    this,
  );
  late final $GroupTasksTableTable groupTasksTable = $GroupTasksTableTable(this);

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    taskEntity,
    workingGroupsTable,
    groupParticipantsTable,
    groupTasksTable,
  ];

  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('working_groups_table', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('group_participants_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('working_groups_table', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('group_tasks_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'group_participants_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('group_tasks_table', kind: UpdateKind.update)],
    ),
  ]);
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
      Value<bool> taskIsSynced,
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
      Value<bool> taskIsSynced,
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

  ColumnFilters<bool> get taskIsSynced =>
      $composableBuilder(column: $table.taskIsSynced, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<bool> get taskIsSynced =>
      $composableBuilder(column: $table.taskIsSynced, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<bool> get taskIsSynced =>
      $composableBuilder(column: $table.taskIsSynced, builder: (column) => column);

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
                Value<bool> taskIsSynced = const Value.absent(),
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
                taskIsSynced: taskIsSynced,
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
                Value<bool> taskIsSynced = const Value.absent(),
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
                taskIsSynced: taskIsSynced,
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
typedef $$WorkingGroupsTableTableCreateCompanionBuilder =
    WorkingGroupsTableCompanion Function({
      required String id,
      required String title,
      Value<String> description,
      required DateTime createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });
typedef $$WorkingGroupsTableTableUpdateCompanionBuilder =
    WorkingGroupsTableCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> description,
      Value<DateTime> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$WorkingGroupsTableTableReferences
    extends BaseReferences<_$AppDatabase, $WorkingGroupsTableTable, WorkingGroupsTableData> {
  $$WorkingGroupsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GroupParticipantsTableTable, List<GroupParticipantsTableData>>
  _groupParticipantsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.groupParticipantsTable,
    aliasName: $_aliasNameGenerator(db.workingGroupsTable.id, db.groupParticipantsTable.groupId),
  );

  $$GroupParticipantsTableTableProcessedTableManager get groupParticipantsTableRefs {
    final manager = $$GroupParticipantsTableTableTableManager(
      $_db,
      $_db.groupParticipantsTable,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_groupParticipantsTableRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$GroupTasksTableTable, List<GroupTasksTableData>>
  _groupTasksTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.groupTasksTable,
    aliasName: $_aliasNameGenerator(db.workingGroupsTable.id, db.groupTasksTable.groupId),
  );

  $$GroupTasksTableTableProcessedTableManager get groupTasksTableRefs {
    final manager = $$GroupTasksTableTableTableManager(
      $_db,
      $_db.groupTasksTable,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_groupTasksTableRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkingGroupsTableTableFilterComposer
    extends Composer<_$AppDatabase, $WorkingGroupsTableTable> {
  $$WorkingGroupsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });

  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description =>
      $composableBuilder(column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> groupParticipantsTableRefs(
    Expression<bool> Function($$GroupParticipantsTableTableFilterComposer f) f,
  ) {
    final $$GroupParticipantsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groupParticipantsTable,
      getReferencedColumn: (t) => t.groupId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$GroupParticipantsTableTableFilterComposer(
            $db: $db,
            $table: $db.groupParticipantsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> groupTasksTableRefs(
    Expression<bool> Function($$GroupTasksTableTableFilterComposer f) f,
  ) {
    final $$GroupTasksTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groupTasksTable,
      getReferencedColumn: (t) => t.groupId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$GroupTasksTableTableFilterComposer(
            $db: $db,
            $table: $db.groupTasksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkingGroupsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkingGroupsTableTable> {
  $$WorkingGroupsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });

  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description =>
      $composableBuilder(column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$WorkingGroupsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkingGroupsTableTable> {
  $$WorkingGroupsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description =>
      $composableBuilder(column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> groupParticipantsTableRefs<T extends Object>(
    Expression<T> Function($$GroupParticipantsTableTableAnnotationComposer a) f,
  ) {
    final $$GroupParticipantsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groupParticipantsTable,
      getReferencedColumn: (t) => t.groupId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$GroupParticipantsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.groupParticipantsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> groupTasksTableRefs<T extends Object>(
    Expression<T> Function($$GroupTasksTableTableAnnotationComposer a) f,
  ) {
    final $$GroupTasksTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groupTasksTable,
      getReferencedColumn: (t) => t.groupId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$GroupTasksTableTableAnnotationComposer(
            $db: $db,
            $table: $db.groupTasksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkingGroupsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkingGroupsTableTable,
          WorkingGroupsTableData,
          $$WorkingGroupsTableTableFilterComposer,
          $$WorkingGroupsTableTableOrderingComposer,
          $$WorkingGroupsTableTableAnnotationComposer,
          $$WorkingGroupsTableTableCreateCompanionBuilder,
          $$WorkingGroupsTableTableUpdateCompanionBuilder,
          (WorkingGroupsTableData, $$WorkingGroupsTableTableReferences),
          WorkingGroupsTableData,
          PrefetchHooks Function({bool groupParticipantsTableRefs, bool groupTasksTableRefs})
        > {
  $$WorkingGroupsTableTableTableManager(_$AppDatabase db, $WorkingGroupsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkingGroupsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkingGroupsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkingGroupsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkingGroupsTableCompanion(
                id: id,
                title: title,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String> description = const Value.absent(),
                required DateTime createdAt,
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkingGroupsTableCompanion.insert(
                id: id,
                title: title,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $$WorkingGroupsTableTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback:
              ({groupParticipantsTableRefs = false, groupTasksTableRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (groupParticipantsTableRefs) db.groupParticipantsTable,
                    if (groupTasksTableRefs) db.groupTasksTable,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (groupParticipantsTableRefs)
                        await $_getPrefetchedData<
                          WorkingGroupsTableData,
                          $WorkingGroupsTableTable,
                          GroupParticipantsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$WorkingGroupsTableTableReferences
                              ._groupParticipantsTableRefsTable(db),
                          managerFromTypedResult: (p0) => $$WorkingGroupsTableTableReferences(
                            db,
                            table,
                            p0,
                          ).groupParticipantsTableRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.groupId == item.id),
                          typedResults: items,
                        ),
                      if (groupTasksTableRefs)
                        await $_getPrefetchedData<
                          WorkingGroupsTableData,
                          $WorkingGroupsTableTable,
                          GroupTasksTableData
                        >(
                          currentTable: table,
                          referencedTable: $$WorkingGroupsTableTableReferences
                              ._groupTasksTableRefsTable(db),
                          managerFromTypedResult: (p0) => $$WorkingGroupsTableTableReferences(
                            db,
                            table,
                            p0,
                          ).groupTasksTableRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.groupId == item.id),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorkingGroupsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkingGroupsTableTable,
      WorkingGroupsTableData,
      $$WorkingGroupsTableTableFilterComposer,
      $$WorkingGroupsTableTableOrderingComposer,
      $$WorkingGroupsTableTableAnnotationComposer,
      $$WorkingGroupsTableTableCreateCompanionBuilder,
      $$WorkingGroupsTableTableUpdateCompanionBuilder,
      (WorkingGroupsTableData, $$WorkingGroupsTableTableReferences),
      WorkingGroupsTableData,
      PrefetchHooks Function({bool groupParticipantsTableRefs, bool groupTasksTableRefs})
    >;
typedef $$GroupParticipantsTableTableCreateCompanionBuilder =
    GroupParticipantsTableCompanion Function({
      required String id,
      required String groupId,
      required String userId,
      required String name,
      Value<String?> avatarUrl,
      Value<int> updatedAt,
      Value<int> rowid,
    });
typedef $$GroupParticipantsTableTableUpdateCompanionBuilder =
    GroupParticipantsTableCompanion Function({
      Value<String> id,
      Value<String> groupId,
      Value<String> userId,
      Value<String> name,
      Value<String?> avatarUrl,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$GroupParticipantsTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $GroupParticipantsTableTable, GroupParticipantsTableData> {
  $$GroupParticipantsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkingGroupsTableTable _groupIdTable(_$AppDatabase db) =>
      db.workingGroupsTable.createAlias(
        $_aliasNameGenerator(db.groupParticipantsTable.groupId, db.workingGroupsTable.id),
      );

  $$WorkingGroupsTableTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$WorkingGroupsTableTableTableManager(
      $_db,
      $_db.workingGroupsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$GroupTasksTableTable, List<GroupTasksTableData>>
  _groupTasksTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.groupTasksTable,
    aliasName: $_aliasNameGenerator(
      db.groupParticipantsTable.id,
      db.groupTasksTable.assignedUserId,
    ),
  );

  $$GroupTasksTableTableProcessedTableManager get groupTasksTableRefs {
    final manager = $$GroupTasksTableTableTableManager(
      $_db,
      $_db.groupTasksTable,
    ).filter((f) => f.assignedUserId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_groupTasksTableRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$GroupParticipantsTableTableFilterComposer
    extends Composer<_$AppDatabase, $GroupParticipantsTableTable> {
  $$GroupParticipantsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });

  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$WorkingGroupsTableTableFilterComposer get groupId {
    final $$WorkingGroupsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.workingGroupsTable,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkingGroupsTableTableFilterComposer(
            $db: $db,
            $table: $db.workingGroupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> groupTasksTableRefs(
    Expression<bool> Function($$GroupTasksTableTableFilterComposer f) f,
  ) {
    final $$GroupTasksTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groupTasksTable,
      getReferencedColumn: (t) => t.assignedUserId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$GroupTasksTableTableFilterComposer(
            $db: $db,
            $table: $db.groupTasksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GroupParticipantsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupParticipantsTableTable> {
  $$GroupParticipantsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });

  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$WorkingGroupsTableTableOrderingComposer get groupId {
    final $$WorkingGroupsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.workingGroupsTable,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkingGroupsTableTableOrderingComposer(
            $db: $db,
            $table: $db.workingGroupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GroupParticipantsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupParticipantsTableTable> {
  $$GroupParticipantsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WorkingGroupsTableTableAnnotationComposer get groupId {
    final $$WorkingGroupsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.workingGroupsTable,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkingGroupsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.workingGroupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> groupTasksTableRefs<T extends Object>(
    Expression<T> Function($$GroupTasksTableTableAnnotationComposer a) f,
  ) {
    final $$GroupTasksTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groupTasksTable,
      getReferencedColumn: (t) => t.assignedUserId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$GroupTasksTableTableAnnotationComposer(
            $db: $db,
            $table: $db.groupTasksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GroupParticipantsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupParticipantsTableTable,
          GroupParticipantsTableData,
          $$GroupParticipantsTableTableFilterComposer,
          $$GroupParticipantsTableTableOrderingComposer,
          $$GroupParticipantsTableTableAnnotationComposer,
          $$GroupParticipantsTableTableCreateCompanionBuilder,
          $$GroupParticipantsTableTableUpdateCompanionBuilder,
          (GroupParticipantsTableData, $$GroupParticipantsTableTableReferences),
          GroupParticipantsTableData,
          PrefetchHooks Function({bool groupId, bool groupTasksTableRefs})
        > {
  $$GroupParticipantsTableTableTableManager(_$AppDatabase db, $GroupParticipantsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupParticipantsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupParticipantsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupParticipantsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupParticipantsTableCompanion(
                id: id,
                groupId: groupId,
                userId: userId,
                name: name,
                avatarUrl: avatarUrl,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required String userId,
                required String name,
                Value<String?> avatarUrl = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupParticipantsTableCompanion.insert(
                id: id,
                groupId: groupId,
                userId: userId,
                name: name,
                avatarUrl: avatarUrl,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable(table), $$GroupParticipantsTableTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({groupId = false, groupTasksTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (groupTasksTableRefs) db.groupTasksTable],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (groupId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.groupId,
                                referencedTable: $$GroupParticipantsTableTableReferences
                                    ._groupIdTable(db),
                                referencedColumn: $$GroupParticipantsTableTableReferences
                                    ._groupIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (groupTasksTableRefs)
                    await $_getPrefetchedData<
                      GroupParticipantsTableData,
                      $GroupParticipantsTableTable,
                      GroupTasksTableData
                    >(
                      currentTable: table,
                      referencedTable: $$GroupParticipantsTableTableReferences
                          ._groupTasksTableRefsTable(db),
                      managerFromTypedResult: (p0) => $$GroupParticipantsTableTableReferences(
                        db,
                        table,
                        p0,
                      ).groupTasksTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.assignedUserId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$GroupParticipantsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupParticipantsTableTable,
      GroupParticipantsTableData,
      $$GroupParticipantsTableTableFilterComposer,
      $$GroupParticipantsTableTableOrderingComposer,
      $$GroupParticipantsTableTableAnnotationComposer,
      $$GroupParticipantsTableTableCreateCompanionBuilder,
      $$GroupParticipantsTableTableUpdateCompanionBuilder,
      (GroupParticipantsTableData, $$GroupParticipantsTableTableReferences),
      GroupParticipantsTableData,
      PrefetchHooks Function({bool groupId, bool groupTasksTableRefs})
    >;
typedef $$GroupTasksTableTableCreateCompanionBuilder =
    GroupTasksTableCompanion Function({
      required String taskId,
      required String groupId,
      Value<String> taskTitle,
      required String taskText,
      Value<int> taskPriority,
      required DateTime taskCreatedAt,
      required List<TaskAttachment> taskAttachments,
      Value<List<TaskSubtask>> taskSubtasks,
      Value<bool> taskIsCompleted,
      Value<DateTime?> taskDeadline,
      Value<bool> taskIsPinned,
      Value<bool> taskIsSynced,
      Value<String?> assignedUserId,
      Value<int> taskUpdatedAt,
      Value<int> rowid,
    });
typedef $$GroupTasksTableTableUpdateCompanionBuilder =
    GroupTasksTableCompanion Function({
      Value<String> taskId,
      Value<String> groupId,
      Value<String> taskTitle,
      Value<String> taskText,
      Value<int> taskPriority,
      Value<DateTime> taskCreatedAt,
      Value<List<TaskAttachment>> taskAttachments,
      Value<List<TaskSubtask>> taskSubtasks,
      Value<bool> taskIsCompleted,
      Value<DateTime?> taskDeadline,
      Value<bool> taskIsPinned,
      Value<bool> taskIsSynced,
      Value<String?> assignedUserId,
      Value<int> taskUpdatedAt,
      Value<int> rowid,
    });

final class $$GroupTasksTableTableReferences
    extends BaseReferences<_$AppDatabase, $GroupTasksTableTable, GroupTasksTableData> {
  $$GroupTasksTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkingGroupsTableTable _groupIdTable(_$AppDatabase db) => db.workingGroupsTable
      .createAlias($_aliasNameGenerator(db.groupTasksTable.groupId, db.workingGroupsTable.id));

  $$WorkingGroupsTableTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$WorkingGroupsTableTableTableManager(
      $_db,
      $_db.workingGroupsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $GroupParticipantsTableTable _assignedUserIdTable(_$AppDatabase db) =>
      db.groupParticipantsTable.createAlias(
        $_aliasNameGenerator(db.groupTasksTable.assignedUserId, db.groupParticipantsTable.id),
      );

  $$GroupParticipantsTableTableProcessedTableManager? get assignedUserId {
    final $_column = $_itemColumn<String>('assigned_user_id');
    if ($_column == null) return null;
    final manager = $$GroupParticipantsTableTableTableManager(
      $_db,
      $_db.groupParticipantsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assignedUserIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$GroupTasksTableTableFilterComposer extends Composer<_$AppDatabase, $GroupTasksTableTable> {
  $$GroupTasksTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });

  ColumnFilters<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => ColumnFilters(column));

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

  ColumnFilters<bool> get taskIsSynced =>
      $composableBuilder(column: $table.taskIsSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get taskUpdatedAt =>
      $composableBuilder(column: $table.taskUpdatedAt, builder: (column) => ColumnFilters(column));

  $$WorkingGroupsTableTableFilterComposer get groupId {
    final $$WorkingGroupsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.workingGroupsTable,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkingGroupsTableTableFilterComposer(
            $db: $db,
            $table: $db.workingGroupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GroupParticipantsTableTableFilterComposer get assignedUserId {
    final $$GroupParticipantsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assignedUserId,
      referencedTable: $db.groupParticipantsTable,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$GroupParticipantsTableTableFilterComposer(
            $db: $db,
            $table: $db.groupParticipantsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GroupTasksTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupTasksTableTable> {
  $$GroupTasksTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });

  ColumnOrderings<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => ColumnOrderings(column));

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

  ColumnOrderings<bool> get taskIsSynced =>
      $composableBuilder(column: $table.taskIsSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get taskUpdatedAt => $composableBuilder(
    column: $table.taskUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkingGroupsTableTableOrderingComposer get groupId {
    final $$WorkingGroupsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.workingGroupsTable,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkingGroupsTableTableOrderingComposer(
            $db: $db,
            $table: $db.workingGroupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GroupParticipantsTableTableOrderingComposer get assignedUserId {
    final $$GroupParticipantsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assignedUserId,
      referencedTable: $db.groupParticipantsTable,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$GroupParticipantsTableTableOrderingComposer(
            $db: $db,
            $table: $db.groupParticipantsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GroupTasksTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupTasksTableTable> {
  $$GroupTasksTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

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

  GeneratedColumn<bool> get taskIsSynced =>
      $composableBuilder(column: $table.taskIsSynced, builder: (column) => column);

  GeneratedColumn<int> get taskUpdatedAt =>
      $composableBuilder(column: $table.taskUpdatedAt, builder: (column) => column);

  $$WorkingGroupsTableTableAnnotationComposer get groupId {
    final $$WorkingGroupsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.workingGroupsTable,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkingGroupsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.workingGroupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GroupParticipantsTableTableAnnotationComposer get assignedUserId {
    final $$GroupParticipantsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assignedUserId,
      referencedTable: $db.groupParticipantsTable,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$GroupParticipantsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.groupParticipantsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GroupTasksTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupTasksTableTable,
          GroupTasksTableData,
          $$GroupTasksTableTableFilterComposer,
          $$GroupTasksTableTableOrderingComposer,
          $$GroupTasksTableTableAnnotationComposer,
          $$GroupTasksTableTableCreateCompanionBuilder,
          $$GroupTasksTableTableUpdateCompanionBuilder,
          (GroupTasksTableData, $$GroupTasksTableTableReferences),
          GroupTasksTableData,
          PrefetchHooks Function({bool groupId, bool assignedUserId})
        > {
  $$GroupTasksTableTableTableManager(_$AppDatabase db, $GroupTasksTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupTasksTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupTasksTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupTasksTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> taskId = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> taskTitle = const Value.absent(),
                Value<String> taskText = const Value.absent(),
                Value<int> taskPriority = const Value.absent(),
                Value<DateTime> taskCreatedAt = const Value.absent(),
                Value<List<TaskAttachment>> taskAttachments = const Value.absent(),
                Value<List<TaskSubtask>> taskSubtasks = const Value.absent(),
                Value<bool> taskIsCompleted = const Value.absent(),
                Value<DateTime?> taskDeadline = const Value.absent(),
                Value<bool> taskIsPinned = const Value.absent(),
                Value<bool> taskIsSynced = const Value.absent(),
                Value<String?> assignedUserId = const Value.absent(),
                Value<int> taskUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupTasksTableCompanion(
                taskId: taskId,
                groupId: groupId,
                taskTitle: taskTitle,
                taskText: taskText,
                taskPriority: taskPriority,
                taskCreatedAt: taskCreatedAt,
                taskAttachments: taskAttachments,
                taskSubtasks: taskSubtasks,
                taskIsCompleted: taskIsCompleted,
                taskDeadline: taskDeadline,
                taskIsPinned: taskIsPinned,
                taskIsSynced: taskIsSynced,
                assignedUserId: assignedUserId,
                taskUpdatedAt: taskUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskId,
                required String groupId,
                Value<String> taskTitle = const Value.absent(),
                required String taskText,
                Value<int> taskPriority = const Value.absent(),
                required DateTime taskCreatedAt,
                required List<TaskAttachment> taskAttachments,
                Value<List<TaskSubtask>> taskSubtasks = const Value.absent(),
                Value<bool> taskIsCompleted = const Value.absent(),
                Value<DateTime?> taskDeadline = const Value.absent(),
                Value<bool> taskIsPinned = const Value.absent(),
                Value<bool> taskIsSynced = const Value.absent(),
                Value<String?> assignedUserId = const Value.absent(),
                Value<int> taskUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupTasksTableCompanion.insert(
                taskId: taskId,
                groupId: groupId,
                taskTitle: taskTitle,
                taskText: taskText,
                taskPriority: taskPriority,
                taskCreatedAt: taskCreatedAt,
                taskAttachments: taskAttachments,
                taskSubtasks: taskSubtasks,
                taskIsCompleted: taskIsCompleted,
                taskDeadline: taskDeadline,
                taskIsPinned: taskIsPinned,
                taskIsSynced: taskIsSynced,
                assignedUserId: assignedUserId,
                taskUpdatedAt: taskUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $$GroupTasksTableTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({groupId = false, assignedUserId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (groupId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.groupId,
                                referencedTable: $$GroupTasksTableTableReferences._groupIdTable(db),
                                referencedColumn: $$GroupTasksTableTableReferences
                                    ._groupIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (assignedUserId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.assignedUserId,
                                referencedTable: $$GroupTasksTableTableReferences
                                    ._assignedUserIdTable(db),
                                referencedColumn: $$GroupTasksTableTableReferences
                                    ._assignedUserIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GroupTasksTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupTasksTableTable,
      GroupTasksTableData,
      $$GroupTasksTableTableFilterComposer,
      $$GroupTasksTableTableOrderingComposer,
      $$GroupTasksTableTableAnnotationComposer,
      $$GroupTasksTableTableCreateCompanionBuilder,
      $$GroupTasksTableTableUpdateCompanionBuilder,
      (GroupTasksTableData, $$GroupTasksTableTableReferences),
      GroupTasksTableData,
      PrefetchHooks Function({bool groupId, bool assignedUserId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;

  $AppDatabaseManager(this._db);

  $$TaskEntityTableTableManager get taskEntity =>
      $$TaskEntityTableTableManager(_db, _db.taskEntity);

  $$WorkingGroupsTableTableTableManager get workingGroupsTable =>
      $$WorkingGroupsTableTableTableManager(_db, _db.workingGroupsTable);

  $$GroupParticipantsTableTableTableManager get groupParticipantsTable =>
      $$GroupParticipantsTableTableTableManager(_db, _db.groupParticipantsTable);

  $$GroupTasksTableTableTableManager get groupTasksTable =>
      $$GroupTasksTableTableTableManager(_db, _db.groupTasksTable);
}
