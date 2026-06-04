import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:collab_tasks/features/tasks/data/remote/aws_graphql_documents.dart';
import 'package:collab_tasks/features/tasks/data/remote/remote_task_mapper.dart';
import 'package:collab_tasks/features/tasks/data/remote/tasks_remote_data_source.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';

class AWSRemoteDataSource implements TasksRemoteDataSource {
  const AWSRemoteDataSource();

  @override
  Future<List<Task>> getTasks({required String ownerId}) async {
    final data = await _query(AwsTaskGraphqlDocuments.listTasks, variables: const {});
    final items = data['listTasks']?['items'];
    if (items is! List) {
      return const [];
    }
    return items
        .whereType<Map>()
        .map((item) => RemoteTaskMapper.fromRemoteMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  @override
  Future<Task?> getTask({required String ownerId, required String taskId}) async {
    final data = await _query(AwsTaskGraphqlDocuments.getTask, variables: {'id': taskId});
    final rawTask = data['getTask'];
    if (rawTask is! Map) {
      return null;
    }
    final task = RemoteTaskMapper.fromRemoteMap(Map<String, dynamic>.from(rawTask));
    return task;
  }

  @override
  Future<void> createTask({required String ownerId, required Task task}) async {
    final input = _toAwsTaskInput(task, ownerId: ownerId);
    await _mutation(AwsTaskGraphqlDocuments.createTask, variables: {'input': input});
  }

  @override
  Future<void> updateTask({required String ownerId, required Task task}) async {
    final input = _toAwsTaskInput(task, ownerId: ownerId);
    await _mutation(AwsTaskGraphqlDocuments.updateTask, variables: {'input': input});
  }

  @override
  Future<void> deleteTask({required String ownerId, required String taskId}) async {
    await _mutation(
      AwsTaskGraphqlDocuments.deleteTask,
      variables: {
        'input': {'id': taskId},
      },
    );
  }

  @override
  Future<TaskAttachment> uploadFile({
    required String ownerId,
    required String taskId,
    required TaskAttachment file,
  }) async {
    final storageKey = 'private/$ownerId/tasks/$taskId/files/${file.id}-${file.name}';
    if (file.bytes != null) {
      final result = await Amplify.Storage.uploadData(
        data: StorageDataPayload.bytes(file.bytes!),
        path: StoragePath.fromString(storageKey),
      ).result;
      return file.copyWith(storageKey: result.uploadedItem.path);
    }

    final localPath = file.localPath;
    if (localPath == null || localPath.isEmpty) {
      throw UnsupportedError('AWS uploadFile requires bytes or localPath.');
    }

    final result = await Amplify.Storage.uploadFile(
      localFile: AWSFile.fromPath(localPath),
      path: StoragePath.fromString(storageKey),
    ).result;
    return file.copyWith(storageKey: result.uploadedItem.path);
  }

  Future<Map<String, dynamic>> _query(String document, {required Map<String, Object?> variables}) {
    final request = GraphQLRequest<String>(document: document, variables: variables);
    return _send(Amplify.API.query(request: request).response);
  }

  Map<String, dynamic> _toAwsTaskInput(Task task, {required String ownerId}) {
    final map = RemoteTaskMapper.toRemoteMap(task, ownerId: ownerId);
    return {
      'id': map['id'],
      'title': map['title'],
      'description': map['description'],
      'deadline': map['deadline'],
      'isCompleted': map['isCompleted'],
      'priority': map['priority'],
      'subtasks': map['subtasks'],
      'files': map['files'],
      'updatedAtMillis': map['updatedAtMillis'],
    };
  }

  Future<Map<String, dynamic>> _mutation(
    String document, {
    required Map<String, Object?> variables,
  }) {
    final request = GraphQLRequest<String>(document: document, variables: variables);
    return _send(Amplify.API.mutate(request: request).response);
  }

  Future<Map<String, dynamic>> _send(Future<GraphQLResponse<String>> responseFuture) async {
    final response = await responseFuture;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.map((error) => error.message).join('; '));
    }
    final data = response.data;
    if (data == null || data.isEmpty) {
      return const {};
    }
    return jsonDecode(data) as Map<String, dynamic>;
  }
}
