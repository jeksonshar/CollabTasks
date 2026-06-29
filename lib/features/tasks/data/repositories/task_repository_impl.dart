import 'dart:async';

import 'package:collab_tasks/core/enums/task_filter_type.dart';
import 'package:collab_tasks/core/enums/task_sort_direction.dart';
import 'package:collab_tasks/core/enums/task_sort_type.dart';
import 'package:collab_tasks/features/auth/domain/repositories/auth_repository.dart';
import 'package:collab_tasks/features/tasks/data/local/tasks_local_data_source.dart';
import 'package:collab_tasks/features/tasks/data/remote/tasks_remote_data_source.dart';
import 'package:collab_tasks/features/tasks/domain/models/errors/data_exception.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';
import 'package:collab_tasks/features/tasks/domain/repositories/task_repository.dart';
import 'package:collab_tasks/features/tasks/domain/services/task_notification_service.dart';
import 'package:flutter/foundation.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TasksLocalDataSource _localDataSource;
  final TasksRemoteDataSource _remoteDataSource;
  final AuthRepository _authRepository;
  final TaskNotificationService _notificationService;

  TaskRepositoryImpl({
    required TasksLocalDataSource localDataSource,
    required TasksRemoteDataSource remoteDataSource,
    required AuthRepository authRepository,
    required TaskNotificationService notificationService,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _authRepository = authRepository,
       _notificationService = notificationService;

  Future<void> _upsertTask(Task task, {required bool createRemote}) async {
    final ownerId = await _requireCurrentOwnerId();
    final freshTask = _withFreshUpdatedAt(task);
    await _localDataSource.upsertTask(ownerId: ownerId, task: freshTask);
    await _tryPushTask(ownerId: ownerId, task: freshTask, createRemote: createRemote);
  }

  Task _withFreshUpdatedAt(Task task) {
    return task.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<void> addTask(Task task) => _upsertTask(task, createRemote: true);

  @override
  Future<void> updateTask(Task task) => _upsertTask(task, createRemote: false);

  @override
  Future<void> deleteTask(String id) async {
    final ownerId = await _requireCurrentOwnerId();
    await _localDataSource.deleteTask(ownerId: ownerId, id: id);
    try {
      await _remoteDataSource.deleteTask(ownerId: ownerId, taskId: id);
    } catch (error, stackTrace) {
      debugPrint('TaskRepository.delete remote failed: $error\n$stackTrace');
    }
  }

  @override
  Stream<List<Task>> watchTasks({
    required String searchQuery,
    required TaskFilterType filterType,
    required TaskSortType sortType,
    required TaskSortDirection sortDirection,
  }) {
    return _authRepository.watchAuthState().asyncExpand((user) async* {
      if (user == null) {
        yield const <Task>[];
        return;
      }

      // Фоновая синхронизация остается без изменений
      unawaited(
        _syncTasksForOwner(user.id).catchError((error, stackTrace) {
          debugPrint('Background sync failed: $error\n$stackTrace');
        }),
      );

      // Просто пробрасываем все параметры из Блока/UseCase напрямую в DataSource
      yield* _localDataSource.watchTasks(
        ownerId: user.id,
        searchQuery: searchQuery,
        filterType: filterType,
        sortType: sortType,
        sortDirection: sortDirection,
      );
    });
  }

  @override
  Future<void> toggleTask(String id) async {
    final ownerId = await _requireCurrentOwnerId();
    final task = await _localDataSource.getTask(ownerId: ownerId, id: id);
    if (task == null) {
      throw DataException('Task with id $id not found');
    }
    final updatedTask = _withFreshUpdatedAt(task.copyWith(isCompleted: !task.isCompleted));
    await _localDataSource.upsertTask(ownerId: ownerId, task: updatedTask);
    await _tryPushTask(ownerId: ownerId, task: updatedTask, createRemote: false);
  }

  @override
  Future<void> syncTasks() async {
    try {
      final ownerId = await _requireCurrentOwnerId();
      unawaited(
        _syncTasksForOwner(ownerId).catchError((error, stackTrace) {
          debugPrint('Background sync failed: $error\n$stackTrace');
        }),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to start background sync: $error\n$stackTrace');
    }
  }

  @override
  Future<Uint8List> getAttachmentBytes(String storageKey) async {
    return _remoteDataSource.downloadAttachmentBytes(storageKey);
  }

  Future<void> _syncTasksForOwner(String ownerId) async {
    try {
      final localTasks = await _localDataSource.getTasks(ownerId: ownerId);
      final remoteTasks = await _remoteDataSource.getTasks(ownerId: ownerId);

      final localById = {for (final task in localTasks) task.id: task};
      final remoteById = {for (final task in remoteTasks) task.id: task};
      final allIds = {...localById.keys, ...remoteById.keys};

      for (final id in allIds) {
        final local = localById[id];
        final remote = remoteById[id];
        Task? syncedTask;

        if (local == null && remote != null) {
          final syncedRemote = remote.copyWith(isSynced: true);
          await _localDataSource.upsertTask(ownerId: ownerId, task: syncedRemote);
          syncedTask = syncedRemote;
        } else if (local != null && remote == null) {
          if (local.isSynced) {
            await _localDataSource.deleteTask(ownerId: ownerId, id: local.id);
          } else {
            await _tryPushTask(ownerId: ownerId, task: local, createRemote: true);
            syncedTask = local;
          }
        } else if (local != null && remote != null) {
          if (local.updatedAt == remote.updatedAt) {
            syncedTask = local;
          } else if (local.updatedAt > remote.updatedAt) {
            await _tryPushTask(ownerId: ownerId, task: local, createRemote: false);
            syncedTask = local;
          } else {
            final syncedRemote = remote.copyWith(isSynced: true);
            await _localDataSource.upsertTask(ownerId: ownerId, task: syncedRemote);
            syncedTask = syncedRemote;
          }
        }

        if (syncedTask != null) {
          await _rescheduleNotificationIfNeeded(syncedTask);
        } else {
          await _notificationService.cancelTaskNotifications(id);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Sync tasks failed: $error\n$stackTrace');
    }
  }

  Future<void> _rescheduleNotificationIfNeeded(Task task) async {
    if (task.isCompleted || task.deadline == null) {
      await _notificationService.cancelTaskNotifications(task.id);
      return;
    }
    final now = DateTime.now();
    if (task.deadline!.isAfter(now)) {
      try {
        await _notificationService.scheduleTaskNotifications(task);
      } catch (e, s) {
        debugPrint('Failed to reschedule notifications for task ${task.id}: $e\n$s');
      }
    } else {
      await _notificationService.cancelTaskNotifications(task.id);
    }
  }

  Future<void> _tryPushTask({
    required String ownerId,
    required Task task,
    required bool createRemote,
  }) async {
    try {
      await _pushTask(ownerId: ownerId, task: task, createRemote: createRemote);
    } catch (error, stackTrace) {
      debugPrint('TaskRepository remote push failed: $error\n$stackTrace');
    }
  }

  Future<void> _pushTask({
    required String ownerId,
    required Task task,
    required bool createRemote,
  }) async {
    final remoteTask = await _withUploadedFiles(ownerId: ownerId, task: task);

    if (createRemote) {
      await _remoteDataSource.createTask(ownerId: ownerId, task: remoteTask);
    } else {
      await _remoteDataSource.updateTask(ownerId: ownerId, task: remoteTask);
    }

    final syncedLocal = remoteTask.copyWith(isSynced: true);
    await _localDataSource.upsertTask(ownerId: ownerId, task: syncedLocal);
  }

  Future<Task> _withUploadedFiles({required String ownerId, required Task task}) async {
    final uploadedFiles = <TaskAttachment>[];
    var changed = false;

    for (final file in task.attachments) {
      if (file.storageKey != null && file.storageKey!.isNotEmpty) {
        uploadedFiles.add(file);
        continue;
      }

      final uploadedFile = await _remoteDataSource.uploadFile(taskId: task.id, file: file);
      uploadedFiles.add(uploadedFile);
      changed = true;
    }

    if (!changed) {
      return task;
    }
    return task.copyWith(attachments: uploadedFiles);
  }

  Future<String> _requireCurrentOwnerId() async {
    final ownerId = await _currentOwnerIdOrNull();
    if (ownerId == null) {
      throw DataException('Cannot sync tasks without an authenticated user.');
    }
    return ownerId;
  }

  Future<String?> _currentOwnerIdOrNull() async {
    final user = await _authRepository.watchAuthState().first;
    return user?.id;
  }
}
