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
  List<GeneratedColumn> get $columns => [taskId, taskText, taskPriority, taskAttachments];

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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId};

  @override
  TaskEntityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskEntityData(
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      taskText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_text'],
      )!,
      taskPriority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_priority'],
      )!,
      taskAttachments: $TaskEntityTable.$convertertaskAttachments.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}task_attachments'],
        )!,
      ),
    );
  }

  @override
  $TaskEntityTable createAlias(String alias) {
    return $TaskEntityTable(attachedDatabase, alias);
  }

  static TypeConverter<List<TaskAttachment>, String> $convertertaskAttachments =
      const TaskAttachmentListConverter();
}

class TaskEntityData extends DataClass implements Insertable<TaskEntityData> {
  final String taskId;
  final String taskText;
  final int taskPriority;
  final List<TaskAttachment> taskAttachments;

  const TaskEntityData({
    required this.taskId,
    required this.taskText,
    required this.taskPriority,
    required this.taskAttachments,
  });

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['task_text'] = Variable<String>(taskText);
    map['task_priority'] = Variable<int>(taskPriority);
    {
      map['task_attachments'] = Variable<String>(
        $TaskEntityTable.$convertertaskAttachments.toSql(taskAttachments),
      );
    }
    return map;
  }

  TaskEntityCompanion toCompanion(bool nullToAbsent) {
    return TaskEntityCompanion(
      taskId: Value(taskId),
      taskText: Value(taskText),
      taskPriority: Value(taskPriority),
      taskAttachments: Value(taskAttachments),
    );
  }

  factory TaskEntityData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskEntityData(
      taskId: serializer.fromJson<String>(json['taskId']),
      taskText: serializer.fromJson<String>(json['taskText']),
      taskPriority: serializer.fromJson<int>(json['taskPriority']),
      taskAttachments: serializer.fromJson<List<TaskAttachment>>(json['taskAttachments']),
    );
  }

  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskId': serializer.toJson<String>(taskId),
      'taskText': serializer.toJson<String>(taskText),
      'taskPriority': serializer.toJson<int>(taskPriority),
      'taskAttachments': serializer.toJson<List<TaskAttachment>>(taskAttachments),
    };
  }

  TaskEntityData copyWith({
    String? taskId,
    String? taskText,
    int? taskPriority,
    List<TaskAttachment>? taskAttachments,
  }) => TaskEntityData(
    taskId: taskId ?? this.taskId,
    taskText: taskText ?? this.taskText,
    taskPriority: taskPriority ?? this.taskPriority,
    taskAttachments: taskAttachments ?? this.taskAttachments,
  );

  TaskEntityData copyWithCompanion(TaskEntityCompanion data) {
    return TaskEntityData(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      taskText: data.taskText.present ? data.taskText.value : this.taskText,
      taskPriority: data.taskPriority.present ? data.taskPriority.value : this.taskPriority,
      taskAttachments: data.taskAttachments.present
          ? data.taskAttachments.value
          : this.taskAttachments,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskEntityData(')
          ..write('taskId: $taskId, ')
          ..write('taskText: $taskText, ')
          ..write('taskPriority: $taskPriority, ')
          ..write('taskAttachments: $taskAttachments')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(taskId, taskText, taskPriority, taskAttachments);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskEntityData &&
          other.taskId == this.taskId &&
          other.taskText == this.taskText &&
          other.taskPriority == this.taskPriority &&
          other.taskAttachments == this.taskAttachments);
}

class TaskEntityCompanion extends UpdateCompanion<TaskEntityData> {
  final Value<String> taskId;
  final Value<String> taskText;
  final Value<int> taskPriority;
  final Value<List<TaskAttachment>> taskAttachments;
  final Value<int> rowid;

  const TaskEntityCompanion({
    this.taskId = const Value.absent(),
    this.taskText = const Value.absent(),
    this.taskPriority = const Value.absent(),
    this.taskAttachments = const Value.absent(),
    this.rowid = const Value.absent(),
  });

  TaskEntityCompanion.insert({
    required String taskId,
    required String taskText,
    this.taskPriority = const Value.absent(),
    required List<TaskAttachment> taskAttachments,
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId),
       taskText = Value(taskText),
       taskAttachments = Value(taskAttachments);

  static Insertable<TaskEntityData> custom({
    Expression<String>? taskId,
    Expression<String>? taskText,
    Expression<int>? taskPriority,
    Expression<String>? taskAttachments,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (taskText != null) 'task_text': taskText,
      if (taskPriority != null) 'task_priority': taskPriority,
      if (taskAttachments != null) 'task_attachments': taskAttachments,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskEntityCompanion copyWith({
    Value<String>? taskId,
    Value<String>? taskText,
    Value<int>? taskPriority,
    Value<List<TaskAttachment>>? taskAttachments,
    Value<int>? rowid,
  }) {
    return TaskEntityCompanion(
      taskId: taskId ?? this.taskId,
      taskText: taskText ?? this.taskText,
      taskPriority: taskPriority ?? this.taskPriority,
      taskAttachments: taskAttachments ?? this.taskAttachments,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (taskText.present) {
      map['task_text'] = Variable<String>(taskText.value);
    }
    if (taskPriority.present) {
      map['task_priority'] = Variable<int>(taskPriority.value);
    }
    if (taskAttachments.present) {
      map['task_attachments'] = Variable<String>(
        $TaskEntityTable.$convertertaskAttachments.toSql(taskAttachments.value),
      );
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
          ..write('taskText: $taskText, ')
          ..write('taskPriority: $taskPriority, ')
          ..write('taskAttachments: $taskAttachments, ')
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
      required String taskText,
      Value<int> taskPriority,
      required List<TaskAttachment> taskAttachments,
      Value<int> rowid,
    });
typedef $$TaskEntityTableUpdateCompanionBuilder =
    TaskEntityCompanion Function({
      Value<String> taskId,
      Value<String> taskText,
      Value<int> taskPriority,
      Value<List<TaskAttachment>> taskAttachments,
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

  ColumnFilters<String> get taskText =>
      $composableBuilder(column: $table.taskText, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get taskPriority =>
      $composableBuilder(column: $table.taskPriority, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<TaskAttachment>, List<TaskAttachment>, String>
  get taskAttachments => $composableBuilder(
    column: $table.taskAttachments,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
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

  ColumnOrderings<String> get taskText =>
      $composableBuilder(column: $table.taskText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get taskPriority =>
      $composableBuilder(column: $table.taskPriority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taskAttachments => $composableBuilder(
    column: $table.taskAttachments,
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

  GeneratedColumn<String> get taskText =>
      $composableBuilder(column: $table.taskText, builder: (column) => column);

  GeneratedColumn<int> get taskPriority =>
      $composableBuilder(column: $table.taskPriority, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<TaskAttachment>, String> get taskAttachments =>
      $composableBuilder(column: $table.taskAttachments, builder: (column) => column);
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
                Value<String> taskText = const Value.absent(),
                Value<int> taskPriority = const Value.absent(),
                Value<List<TaskAttachment>> taskAttachments = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskEntityCompanion(
                taskId: taskId,
                taskText: taskText,
                taskPriority: taskPriority,
                taskAttachments: taskAttachments,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskId,
                required String taskText,
                Value<int> taskPriority = const Value.absent(),
                required List<TaskAttachment> taskAttachments,
                Value<int> rowid = const Value.absent(),
              }) => TaskEntityCompanion.insert(
                taskId: taskId,
                taskText: taskText,
                taskPriority: taskPriority,
                taskAttachments: taskAttachments,
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
