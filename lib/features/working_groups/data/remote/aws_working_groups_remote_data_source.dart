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
  Stream<List<WorkingGroup>> watchGroups({
    required String userId,
    required String userEmail,
  }) async* {
    yield await _listGroups(userId: userId, userEmail: userEmail);
    yield* _subscribeList<WorkingGroup>(
      AwsWorkingGroupsGraphqlDocuments.onGroupChanged,
      variables: const {},
      rootKey: 'onCreateWorkingGroup',
      mapper: WorkingGroup.fromMap,
    ).where((group) => _isGroupVisibleToUser(group, userId, userEmail)).map((group) => [group]);
  }

  @override
  Future<List<WorkingGroup>> fetchGroups({required String userId, required String userEmail}) =>
      _listGroups(userId: userId, userEmail: userEmail);

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
    List<String> participantUserIds = const [],
    List<String> participantEmails = const [],
  }) {
    return _createOrUpdate(
      createDocument: AwsWorkingGroupsGraphqlDocuments.createGroup,
      updateDocument: AwsWorkingGroupsGraphqlDocuments.updateGroup,
      input: _groupInput(
        group,
        participantUserIds: participantUserIds,
        participantEmails: participantEmails,
      ),
    );
  }

  @override
  Future<void> deleteGroup(String groupId) {
    return _mutation(
      AwsWorkingGroupsGraphqlDocuments.deleteGroup,
      variables: {
        'input': {'id': groupId},
      },
    );
  }

  @override
  Future<void> inviteParticipantByEmail({required String groupId, required String email}) {
    return _mutation(
      AwsWorkingGroupsGraphqlDocuments.inviteParticipantByEmail,
      variables: {'groupId': groupId, 'email': email.trim().toLowerCase()},
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
  Future<bool> isGroupMember({
    required String groupId,
    required String userId,
    required String userEmail,
  }) async {
    final raw = await _findRawGroup(groupId);
    if (raw == null) return false;
    return _rawGroupVisibleToUser(raw, userId, userEmail);
  }

  @override
  Future<void> leaveGroup({
    required String groupId,
    required String userId,
    required String userEmail,
    required List<String> participantIds,
  }) async {
    // Remove the user from the group's visibility arrays first, so the group
    // stops being listed for them and they are not re-added on the next sync.
    await _removeUserFromGroupArrays(groupId: groupId, userId: userId, userEmail: userEmail);
    for (final participantId in participantIds) {
      await _mutation(
        AwsWorkingGroupsGraphqlDocuments.deleteParticipant,
        variables: {
          'input': {'id': participantId},
        },
      );
    }
  }

  Future<void> _removeUserFromGroupArrays({
    required String groupId,
    required String userId,
    required String userEmail,
  }) async {
    final raw = await _findRawGroup(groupId);
    if (raw == null) return;
    final normalizedEmail = userEmail.trim().toLowerCase();
    final userIds =
        (raw['participantUserIds'] as List?)
            ?.whereType<String>()
            .where((id) => id != userId)
            .toList(growable: false) ??
        const <String>[];
    final emails =
        (raw['participantEmails'] as List?)
            ?.whereType<String>()
            .where((email) => email.trim().toLowerCase() != normalizedEmail)
            .toList(growable: false) ??
        const <String>[];
    await _mutation(
      AwsWorkingGroupsGraphqlDocuments.updateGroup,
      variables: {
        'input': {'id': groupId, 'participantUserIds': userIds, 'participantEmails': emails},
      },
    );
  }

  Future<Map?> _findRawGroup(String groupId) async {
    final data = await _query(AwsWorkingGroupsGraphqlDocuments.listGroups, variables: const {});
    final items = data['listWorkingGroups']?['items'];
    if (items is! List) return null;
    for (final item in items.whereType<Map>()) {
      if (item['id'] == groupId) return item;
    }
    return null;
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

  Future<List<WorkingGroup>> _listGroups({
    required String userId,
    required String userEmail,
  }) async {
    final data = await _query(AwsWorkingGroupsGraphqlDocuments.listGroups, variables: const {});
    final items = data['listWorkingGroups']?['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .where((item) => _rawGroupVisibleToUser(item, userId, userEmail))
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
        .asyncExpand((response) async* {
          try {
            final decoded = jsonDecode(response.data!) as Map<String, dynamic>;
            final rawObject = decoded[rootKey];

            // Защита от Null: если объект пустой — просто пропускаем ивент
            if (rawObject is Map) {
              yield mapper(Map<String, dynamic>.from(rawObject));
            }
          } catch (e, stack) {
            safePrint('Error parsing subscription data: $e\n$stack');
          }
        });
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

  Map<String, Object?> _groupInput(
    WorkingGroup group, {
    required List<String> participantUserIds,
    required List<String> participantEmails,
  }) {
    final input = <String, Object?>{
      'id': group.id,
      'title': group.title,
      'description': group.description,
      'avatarUrl': group.avatarUrl,
      'updatedAtMillis': group.updatedAt,
    };
    if (participantUserIds.isNotEmpty) {
      input['participantUserIds'] = participantUserIds;
    }
    if (participantEmails.isNotEmpty) {
      input['participantEmails'] = participantEmails.map((email) => email.toLowerCase()).toList();
    }
    return input;
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

  bool _rawGroupVisibleToUser(Map item, String userId, String userEmail) {
    final participantUserIds = item['participantUserIds'];
    final participantEmails = item['participantEmails'];
    return participantUserIds is List && participantUserIds.contains(userId) ||
        participantEmails is List && participantEmails.contains(userEmail.trim().toLowerCase());
  }

  bool _isGroupVisibleToUser(WorkingGroup group, String userId, String userEmail) {
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
