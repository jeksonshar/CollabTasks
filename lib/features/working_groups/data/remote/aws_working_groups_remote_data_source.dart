import 'dart:async';
import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:collab_tasks/features/working_groups/data/remote/aws_working_groups_graphql_documents.dart';
import 'package:collab_tasks/features/working_groups/data/remote/working_groups_remote_data_source.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';

class AWSWorkingGroupsRemoteDataSource implements WorkingGroupsRemoteDataSource {
  const AWSWorkingGroupsRemoteDataSource();

  @override
  Stream<List<WorkingGroup>> watchGroups({required String userId}) async* {
    yield await _listGroups(userId: userId);
    yield* _subscribeList<WorkingGroup>(
      AwsWorkingGroupsGraphqlDocuments.onGroupChanged,
      variables: const {},
      rootKey: 'onCreateWorkingGroup',
      mapper: WorkingGroup.fromMap,
    ).where((group) => _isGroupVisibleToUser(group, userId)).map((group) => [group]);
  }

  @override
  Stream<List<GroupParticipant>> watchParticipants({required String groupId}) async* {
    yield await _listParticipants(groupId);
    yield* _subscribeList<GroupParticipant>(
      AwsWorkingGroupsGraphqlDocuments.onParticipantChanged,
      variables: {'groupId': groupId},
      rootKey: 'onCreateGroupParticipant',
      mapper: GroupParticipant.fromMap,
    ).map((participant) => [participant]);
  }

  @override
  Stream<List<GroupTask>> watchTasks({required String groupId}) async* {
    yield await _listTasks(groupId);
    yield* _subscribeList<GroupTask>(
      AwsWorkingGroupsGraphqlDocuments.onTaskChanged,
      variables: {'groupId': groupId},
      rootKey: 'onCreateGroupTask',
      mapper: GroupTask.fromMap,
    ).map((task) => [task]);
  }

  @override
  Future<void> upsertGroup({
    required WorkingGroup group,
    required List<String> participantUserIds,
  }) {
    return _createOrUpdate(
      createDocument: AwsWorkingGroupsGraphqlDocuments.createGroup,
      updateDocument: AwsWorkingGroupsGraphqlDocuments.updateGroup,
      input: _groupInput(group, participantUserIds: participantUserIds),
    );
  }

  @override
  Future<void> upsertParticipant(GroupParticipant participant) {
    return _createOrUpdate(
      createDocument: AwsWorkingGroupsGraphqlDocuments.createParticipant,
      updateDocument: AwsWorkingGroupsGraphqlDocuments.updateParticipant,
      input: participant.toMap(),
    );
  }

  @override
  Future<void> upsertTask(GroupTask task) {
    return _createOrUpdate(
      createDocument: AwsWorkingGroupsGraphqlDocuments.createTask,
      updateDocument: AwsWorkingGroupsGraphqlDocuments.updateTask,
      input: _taskInput(task),
    );
  }

  @override
  Future<void> deleteTask({required String groupId, required String taskId}) {
    return _mutation(
      AwsWorkingGroupsGraphqlDocuments.deleteTask,
      variables: {
        'input': {'id': taskId},
      },
    );
  }

  @override
  Future<void> claimTask({
    required String groupId,
    required String taskId,
    required String participantId,
    required int updatedAt,
  }) {
    return _mutation(
      AwsWorkingGroupsGraphqlDocuments.updateTask,
      variables: {
        'input': {'id': taskId, 'assignedUserId': participantId, 'updatedAtMillis': updatedAt},
      },
    );
  }

  Future<List<WorkingGroup>> _listGroups({required String userId}) async {
    final data = await _query(AwsWorkingGroupsGraphqlDocuments.listGroups, variables: const {});
    final items = data['listWorkingGroups']?['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .where((item) => _rawGroupVisibleToUser(item, userId))
        .map((item) => WorkingGroup.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<GroupParticipant>> _listParticipants(String groupId) async {
    final data = await _query(
      AwsWorkingGroupsGraphqlDocuments.listParticipants,
      variables: {'groupId': groupId},
    );
    final items = data['listGroupParticipants']?['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => GroupParticipant.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<GroupTask>> _listTasks(String groupId) async {
    final data = await _query(
      AwsWorkingGroupsGraphqlDocuments.listTasks,
      variables: {'groupId': groupId},
    );
    final items = data['listGroupTasks']?['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => GroupTask.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Stream<T> _subscribeList<T>(
    String document, {
    required Map<String, Object?> variables,
    required String rootKey,
    required T Function(Map<String, dynamic>) mapper,
  }) {
    final request = GraphQLRequest<String>(document: document, variables: variables);
    return Amplify.API
        .subscribe(request, onEstablished: () {})
        .where((response) => response.data != null && response.data!.isNotEmpty)
        .map(
          (response) =>
              mapper(Map<String, dynamic>.from(jsonDecode(response.data!)[rootKey] as Map)),
        );
  }

  Future<Map<String, dynamic>> _query(String document, {required Map<String, Object?> variables}) {
    final request = GraphQLRequest<String>(document: document, variables: variables);
    return _send(Amplify.API.query(request: request).response);
  }

  Future<void> _mutation(String document, {required Map<String, Object?> variables}) async {
    final request = GraphQLRequest<String>(document: document, variables: variables);
    await _send(Amplify.API.mutate(request: request).response);
  }

  Future<void> _createOrUpdate({
    required String createDocument,
    required String updateDocument,
    required Map<String, Object?> input,
  }) async {
    try {
      await _mutation(createDocument, variables: {'input': input});
    } catch (_) {
      await _mutation(updateDocument, variables: {'input': input});
    }
  }

  Map<String, Object?> _groupInput(WorkingGroup group, {required List<String> participantUserIds}) {
    return {
      'id': group.id,
      'title': group.title,
      'description': group.description,
      'participantUserIds': participantUserIds,
      'updatedAtMillis': group.updatedAt,
    };
  }

  Map<String, Object?> _taskInput(GroupTask task) {
    return {
      'id': task.id,
      'groupId': task.groupId,
      'title': task.title,
      'description': task.description,
      'deadline': task.deadline?.millisecondsSinceEpoch,
      'isCompleted': task.isCompleted,
      'priority': _priorityToRemote(task.priority),
      'subtasks': task.subtasks
          .map(
            (subtask) => {
              'id': subtask.id,
              'title': subtask.title,
              'isCompleted': subtask.isCompleted,
            },
          )
          .toList(growable: false),
      'files': task.attachments
          .map(
            (file) => {
              'id': file.id,
              'name': file.name,
              'storageKey': file.storageKey ?? '',
              'sizeBytes': file.sizeBytes,
            },
          )
          .toList(growable: false),
      'isPinned': task.isPinned,
      'assignedUserId': task.assignedUserId,
      'updatedAtMillis': task.updatedAt,
    };
  }

  bool _rawGroupVisibleToUser(Map item, String userId) {
    final participantUserIds = item['participantUserIds'];
    return participantUserIds is List && participantUserIds.contains(userId);
  }

  bool _isGroupVisibleToUser(WorkingGroup group, String userId) {
    return true;
  }

  String _priorityToRemote(int priority) {
    return switch (priority) {
      1 => 'low',
      2 => 'medium',
      3 => 'high',
      _ => 'none',
    };
  }

  Future<Map<String, dynamic>> _send(Future<GraphQLResponse<String>> responseFuture) async {
    final response = await responseFuture;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.map((error) => error.message).join('; '));
    }
    final data = response.data;
    if (data == null || data.isEmpty) return const {};
    return jsonDecode(data) as Map<String, dynamic>;
  }
}
