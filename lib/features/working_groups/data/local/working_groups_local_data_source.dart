import 'package:collab_tasks/features/tasks/data/local/db/app_database.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:drift/drift.dart';

abstract class WorkingGroupsLocalDataSource {
  Stream<List<WorkingGroup>> watchGroups();

  Stream<List<GroupParticipant>> watchParticipants(String groupId);

  Stream<List<GroupTask>> watchTasks(String groupId);

  Future<List<WorkingGroup>> getGroups();

  Future<List<GroupParticipant>> getParticipants(String groupId);

  Future<GroupTask?> getTask({required String groupId, required String taskId});

  Future<GroupParticipant?> getParticipantByUserId({
    required String groupId,
    required String userId,
  });

  Future<void> upsertGroup(WorkingGroup group);

  Future<void> upsertParticipant(GroupParticipant participant);

  Future<void> upsertTask(GroupTask task);

  Future<void> deleteTask({required String groupId, required String taskId});
}

class DriftWorkingGroupsLocalDataSource implements WorkingGroupsLocalDataSource {
  const DriftWorkingGroupsLocalDataSource(this._db);

  final AppDatabase _db;

  @override
  Stream<List<WorkingGroup>> watchGroups() {
    return (_db.select(_db.workingGroupsTable)
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .watch()
        .map((rows) => rows.map((row) => row.toModel()).toList(growable: false));
  }

  @override
  Stream<List<GroupParticipant>> watchParticipants(String groupId) {
    return (_db.select(_db.groupParticipantsTable)
          ..where((row) => row.groupId.equals(groupId))
          ..orderBy([(row) => OrderingTerm.asc(row.name)]))
        .watch()
        .map((rows) => rows.map((row) => row.toModel()).toList(growable: false));
  }

  @override
  Stream<List<GroupTask>> watchTasks(String groupId) {
    return (_db.select(_db.groupTasksTable)
          ..where((row) => row.groupId.equals(groupId))
          ..orderBy([(row) => OrderingTerm.desc(row.taskCreatedAt)]))
        .watch()
        .map((rows) => rows.map((row) => row.toModel()).toList(growable: false));
  }

  @override
  Future<List<WorkingGroup>> getGroups() async {
    final rows = await _db.select(_db.workingGroupsTable).get();
    return rows.map((row) => row.toModel()).toList(growable: false);
  }

  @override
  Future<List<GroupParticipant>> getParticipants(String groupId) async {
    final rows = await (_db.select(
      _db.groupParticipantsTable,
    )..where((row) => row.groupId.equals(groupId))).get();
    return rows.map((row) => row.toModel()).toList(growable: false);
  }

  @override
  Future<GroupTask?> getTask({required String groupId, required String taskId}) async {
    final row = await (_db.select(
      _db.groupTasksTable,
    )..where((t) => t.groupId.equals(groupId) & t.taskId.equals(taskId))).getSingleOrNull();
    return row?.toModel();
  }

  @override
  Future<GroupParticipant?> getParticipantByUserId({
    required String groupId,
    required String userId,
  }) async {
    final row = await (_db.select(
      _db.groupParticipantsTable,
    )..where((p) => p.groupId.equals(groupId) & p.userId.equals(userId))).getSingleOrNull();
    return row?.toModel();
  }

  @override
  Future<void> upsertGroup(WorkingGroup group) {
    final companion = WorkingGroupsTableCompanion.insert(
      id: group.id,
      title: group.title,
      description: Value(group.description),
      createdAt: group.createdAt,
      updatedAt: Value(group.updatedAt),
    );
    return _db
        .into(_db.workingGroupsTable)
        .insert(companion, onConflict: DoUpdate((_) => companion));
  }

  @override
  Future<void> upsertParticipant(GroupParticipant participant) {
    final companion = GroupParticipantsTableCompanion.insert(
      id: participant.id,
      groupId: participant.groupId,
      userId: participant.userId,
      name: participant.name,
      avatarUrl: Value(participant.avatarUrl),
      updatedAt: Value(participant.updatedAt),
    );
    return _db
        .into(_db.groupParticipantsTable)
        .insert(companion, onConflict: DoUpdate((_) => companion));
  }

  @override
  Future<void> upsertTask(GroupTask task) {
    final companion = GroupTasksTableCompanion.insert(
      taskId: task.id,
      groupId: task.groupId,
      taskTitle: Value(task.title),
      taskText: task.description,
      taskPriority: Value(task.priority),
      taskCreatedAt: task.createdAt,
      taskAttachments: task.attachments,
      taskSubtasks: Value(task.subtasks),
      taskIsCompleted: Value(task.isCompleted),
      taskDeadline: Value(task.deadline),
      taskIsPinned: Value(task.isPinned),
      taskIsSynced: Value(task.isSynced),
      assignedUserId: Value(task.assignedUserId),
      taskUpdatedAt: Value(task.updatedAt),
    );
    return _db.into(_db.groupTasksTable).insert(companion, onConflict: DoUpdate((_) => companion));
  }

  @override
  Future<void> deleteTask({required String groupId, required String taskId}) {
    return (_db.delete(
      _db.groupTasksTable,
    )..where((t) => t.groupId.equals(groupId) & t.taskId.equals(taskId))).go();
  }
}

extension WorkingGroupRowMapper on WorkingGroupsTableData {
  WorkingGroup toModel() => WorkingGroup(
    id: id,
    title: title,
    description: description,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension GroupParticipantRowMapper on GroupParticipantsTableData {
  GroupParticipant toModel() => GroupParticipant(
    id: id,
    groupId: groupId,
    userId: userId,
    name: name,
    avatarUrl: avatarUrl,
    updatedAt: updatedAt,
  );
}

extension GroupTaskRowMapper on GroupTasksTableData {
  GroupTask toModel() => GroupTask(
    id: taskId,
    groupId: groupId,
    createdAt: taskCreatedAt,
    title: taskTitle,
    description: taskText,
    priority: taskPriority,
    attachments: taskAttachments,
    subtasks: taskSubtasks,
    isCompleted: taskIsCompleted,
    deadline: taskDeadline,
    isPinned: taskIsPinned,
    isSynced: taskIsSynced,
    assignedUserId: assignedUserId,
    updatedAt: taskUpdatedAt,
  );
}
