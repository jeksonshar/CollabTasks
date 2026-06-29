import 'dart:async';
import 'dart:typed_data';

import 'package:collab_tasks/core/enums/task_filter_type.dart';
import 'package:collab_tasks/core/enums/task_sort_direction.dart';
import 'package:collab_tasks/core/enums/task_sort_type.dart';
import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:collab_tasks/features/auth/domain/failures/failure.dart';
import 'package:collab_tasks/features/auth/domain/repositories/auth_repository.dart';
import 'package:collab_tasks/features/auth/domain/result/result.dart';
import 'package:collab_tasks/features/tasks/data/local/tasks_local_data_source.dart';
import 'package:collab_tasks/features/tasks/data/notifications/notification_tap_payload.dart';
import 'package:collab_tasks/features/tasks/data/remote/tasks_remote_data_source.dart';
import 'package:collab_tasks/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';
import 'package:collab_tasks/features/tasks/domain/services/task_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeTasksLocalDataSource localDataSource;
  late FakeTasksRemoteDataSource remoteDataSource;
  late FakeAuthRepository authRepository;
  late FakeTaskNotificationService notificationService;
  late TaskRepositoryImpl repository;

  setUp(() {
    localDataSource = FakeTasksLocalDataSource();
    remoteDataSource = FakeTasksRemoteDataSource();
    authRepository = const FakeAuthRepository(
      AuthUser(id: 'user-1', email: 'user@example.com', isEmailVerified: true),
    );
    notificationService = FakeTaskNotificationService();
    repository = TaskRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      authRepository: authRepository,
      notificationService: notificationService,
    );
  });

  group('TaskRepositoryImpl remote sync', () {
    test('pulls remote-only tasks into local storage and marks them synced', () async {
      final remoteTask = task(
        id: 'remote-only',
        title: 'Remote only',
        updatedAt: 10,
        deadline: DateTime.now().add(const Duration(days: 1)),
      );
      remoteDataSource.seed(ownerId: 'user-1', tasks: [remoteTask]);

      await repository.syncTasks();
      await waitUntil(() => localDataSource.task('user-1', 'remote-only') != null);

      final localTask = localDataSource.task('user-1', 'remote-only');
      expect(localTask, remoteTask.copyWith(isSynced: true));
      expect(notificationService.scheduledTaskIds, ['remote-only']);
    });

    test('pushes unsynced local-only tasks to remote storage', () async {
      final localTask = task(id: 'local-only', title: 'Local only', updatedAt: 10);
      await localDataSource.upsertTask(ownerId: 'user-1', task: localTask);

      await repository.syncTasks();
      await waitUntil(() => remoteDataSource.createdTaskIds.contains('local-only'));

      expect(remoteDataSource.task('user-1', 'local-only'), localTask);
      expect(localDataSource.task('user-1', 'local-only')!.isSynced, isTrue);
    });

    test('deletes locally synced tasks that no longer exist remotely', () async {
      final deletedRemoteTask = task(
        id: 'deleted-remotely',
        title: 'Deleted remotely',
        isSynced: true,
        updatedAt: 10,
      );
      await localDataSource.upsertTask(ownerId: 'user-1', task: deletedRemoteTask);

      await repository.syncTasks();
      await waitUntil(() => localDataSource.task('user-1', 'deleted-remotely') == null);

      expect(notificationService.cancelledTaskIds, contains('deleted-remotely'));
    });

    test('updates remote storage when local task is newer', () async {
      final olderRemote = task(id: 'task-1', title: 'Remote old', updatedAt: 10);
      final newerLocal = task(id: 'task-1', title: 'Local new', updatedAt: 20);
      remoteDataSource.seed(ownerId: 'user-1', tasks: [olderRemote]);
      await localDataSource.upsertTask(ownerId: 'user-1', task: newerLocal);

      await repository.syncTasks();
      await waitUntil(() => remoteDataSource.updatedTaskIds.contains('task-1'));

      expect(remoteDataSource.task('user-1', 'task-1')!.title, 'Local new');
      expect(localDataSource.task('user-1', 'task-1')!.isSynced, isTrue);
    });

    test('overwrites local storage when remote task is newer', () async {
      final olderLocal = task(id: 'task-1', title: 'Local old', updatedAt: 10);
      final newerRemote = task(id: 'task-1', title: 'Remote new', updatedAt: 20);
      remoteDataSource.seed(ownerId: 'user-1', tasks: [newerRemote]);
      await localDataSource.upsertTask(ownerId: 'user-1', task: olderLocal);

      await repository.syncTasks();
      await waitUntil(() => localDataSource.task('user-1', 'task-1')?.title == 'Remote new');

      expect(localDataSource.task('user-1', 'task-1'), newerRemote.copyWith(isSynced: true));
      expect(remoteDataSource.updatedTaskIds, isEmpty);
    });

    test('uploads local attachments before creating a remote task', () async {
      final attachment = TaskAttachment(
        id: 'file-1',
        name: 'notes.txt',
        extension: 'txt',
        sizeBytes: 5,
        bytes: Uint8List.fromList([1, 2, 3, 4, 5]),
      );
      final localTask = task(
        id: 'task-with-file',
        title: 'Task with file',
        attachments: [attachment],
      );

      await repository.addTask(localTask);

      final remoteTask = remoteDataSource.task('user-1', 'task-with-file')!;
      expect(remoteDataSource.uploadedFiles, ['file-1']);
      expect(remoteTask.attachments.single.storageKey, 'remote/task-with-file/file-1-notes.txt');
      expect(localDataSource.task('user-1', 'task-with-file')!.isSynced, isTrue);
      expect(
        localDataSource.task('user-1', 'task-with-file')!.attachments.single.storageKey,
        'remote/task-with-file/file-1-notes.txt',
      );
    });
  });
}

Task task({
  required String id,
  required String title,
  int updatedAt = 0,
  bool isSynced = false,
  DateTime? deadline,
  List<TaskAttachment> attachments = const [],
}) {
  return Task(
    id: id,
    createdAt: DateTime.utc(2026),
    title: title,
    description: 'Description',
    updatedAt: updatedAt,
    isSynced: isSynced,
    deadline: deadline,
    attachments: attachments,
  );
}

Future<void> waitUntil(bool Function() condition) async {
  for (var i = 0; i < 50; i++) {
    if (condition()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for async repository sync.');
}

class FakeTasksLocalDataSource implements TasksLocalDataSource {
  final Map<String, Map<String, Task>> _tasksByOwner = {};

  Task? task(String ownerId, String id) => _tasksByOwner[ownerId]?[id];

  @override
  Future<void> deleteTask({required String ownerId, required String id}) async {
    _tasksByOwner[ownerId]?.remove(id);
  }

  @override
  Future<Task?> getTask({required String ownerId, required String id}) async {
    return task(ownerId, id);
  }

  @override
  Future<List<Task>> getTasks({required String ownerId}) async {
    return _tasksByOwner[ownerId]?.values.toList(growable: false) ?? const [];
  }

  @override
  Future<void> upsertTask({required String ownerId, required Task task}) async {
    _tasksByOwner.putIfAbsent(ownerId, () => {})[task.id] = task;
  }

  @override
  Stream<List<Task>> watchTasks({
    required String ownerId,
    required String searchQuery,
    required TaskFilterType filterType,
    required TaskSortType sortType,
    required TaskSortDirection sortDirection,
  }) {
    return Stream.value(_tasksByOwner[ownerId]?.values.toList(growable: false) ?? const []);
  }
}

class FakeTasksRemoteDataSource implements TasksRemoteDataSource {
  final Map<String, Map<String, Task>> _tasksByOwner = {};
  final List<String> createdTaskIds = [];
  final List<String> updatedTaskIds = [];
  final List<String> deletedTaskIds = [];
  final List<String> uploadedFiles = [];

  void seed({required String ownerId, required List<Task> tasks}) {
    _tasksByOwner[ownerId] = {for (final task in tasks) task.id: task};
  }

  Task? task(String ownerId, String id) => _tasksByOwner[ownerId]?[id];

  @override
  Future<void> createTask({required String ownerId, required Task task}) async {
    createdTaskIds.add(task.id);
    _tasksByOwner.putIfAbsent(ownerId, () => {})[task.id] = task;
  }

  @override
  Future<void> deleteTask({required String ownerId, required String taskId}) async {
    deletedTaskIds.add(taskId);
    _tasksByOwner[ownerId]?.remove(taskId);
  }

  @override
  Future<Uint8List> downloadAttachmentBytes(String storageKey) async {
    return Uint8List.fromList(storageKey.codeUnits);
  }

  @override
  Future<Task?> getTask({required String ownerId, required String taskId}) async {
    return task(ownerId, taskId);
  }

  @override
  Future<List<Task>> getTasks({required String ownerId}) async {
    return _tasksByOwner[ownerId]?.values.toList(growable: false) ?? const [];
  }

  @override
  Future<void> updateTask({required String ownerId, required Task task}) async {
    updatedTaskIds.add(task.id);
    _tasksByOwner.putIfAbsent(ownerId, () => {})[task.id] = task;
  }

  @override
  Future<TaskAttachment> uploadFile({required String taskId, required TaskAttachment file}) async {
    uploadedFiles.add(file.id);
    return file.copyWith(storageKey: 'remote/$taskId/${file.id}-${file.name}');
  }
}

class FakeAuthRepository implements AuthRepository {
  const FakeAuthRepository(this.user);

  final AuthUser? user;

  @override
  Future<Result<AuthUser, Failure>> loginWithEmail({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void, Failure>> logOut() {
    throw UnimplementedError();
  }

  @override
  Future<Result<AuthUser, Failure>> registerWithEmail({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void, Failure>> resetPassword({required String email}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<AuthUser, Failure>> signInWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Stream<AuthUser?> watchAuthState() => Stream.value(user);
}

class FakeTaskNotificationService implements TaskNotificationService {
  final List<String> scheduledTaskIds = [];
  final List<String> cancelledTaskIds = [];

  @override
  NotificationTapPayload? consumeInitialTapPayload() => null;

  @override
  Future<void> cancelAllNotifications() async {}

  @override
  Future<void> cancelTaskNotifications(String taskId) async {
    cancelledTaskIds.add(taskId);
  }

  @override
  Stream<NotificationTapPayload> get notificationTapStream => const Stream.empty();

  @override
  Future<void> scheduleTaskNotifications(Task task) async {
    scheduledTaskIds.add(task.id);
  }
}
