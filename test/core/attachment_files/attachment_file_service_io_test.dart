import 'dart:io';

import 'package:collab_tasks/core/attachment_files/attachment_file_service_io.dart';
import 'package:collab_tasks/core/enums/task_filter_type.dart';
import 'package:collab_tasks/core/enums/task_sort_direction.dart';
import 'package:collab_tasks/core/enums/task_sort_type.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';
import 'package:collab_tasks/features/tasks/domain/repositories/task_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('collab_tasks_attachments_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (call) async {
        if (call.method == 'getTemporaryDirectory') {
          return tempDir.path;
        }
        return null;
      },
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      null,
    );
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('attachment file IO helpers', () {
    test('reads text attachments and ignores unsupported extensions', () async {
      final textFile = File(p.join(tempDir.path, 'notes.txt'));
      await textFile.writeAsString('task notes');

      final textAttachment = TaskAttachment(
        id: 'file-1',
        name: 'notes.txt',
        extension: 'txt',
        localPath: textFile.path,
        sizeBytes: await textFile.length(),
      );
      final pdfAttachment = textAttachment.copyWith(
        id: 'file-2',
        name: 'report.pdf',
        extension: 'pdf',
      );

      expect(await tryReadTextAttachment(textAttachment), 'task notes');
      expect(await tryReadTextAttachment(pdfAttachment), isNull);
    });

    test('removes existing local attachment files from disk', () async {
      final file = File(p.join(tempDir.path, 'delete-me.txt'));
      await file.writeAsString('temporary');

      final removed = await removeAttachmentFile(
        TaskAttachment(
          id: 'file-1',
          name: 'delete-me.txt',
          extension: 'txt',
          localPath: file.path,
          sizeBytes: await file.length(),
        ),
      );

      expect(removed, isTrue);
      expect(file.existsSync(), isFalse);
    });

    test('treats remote-only and already-missing local files as removed', () async {
      final remoteOnlyRemoved = await removeAttachmentFile(
        const TaskAttachment(
          id: 'file-1',
          name: 'remote.pdf',
          extension: 'pdf',
          storageKey: 'remote/key.pdf',
          sizeBytes: 42,
        ),
      );

      final missingLocalRemoved = await removeAttachmentFile(
        TaskAttachment(
          id: 'file-2',
          name: 'missing.txt',
          extension: 'txt',
          localPath: p.join(tempDir.path, 'missing.txt'),
          sizeBytes: 0,
        ),
      );

      expect(remoteOnlyRemoved, isTrue);
      expect(missingLocalRemoved, isTrue);
    });

    test('downloads remote attachment bytes to cache through repository', () async {
      final repository = FakeTaskRepository(Uint8List.fromList([1, 2, 3, 4]));
      const attachment = TaskAttachment(
        id: 'file-1',
        name: 'remote.txt',
        extension: 'txt',
        storageKey: 'remote/storage/key.txt',
        sizeBytes: 4,
      );

      final cachedPath = await downloadRemoteAttachmentToCache(attachment, repository);
      final cachedFile = File(cachedPath);

      expect(repository.requestedStorageKeys, ['remote/storage/key.txt']);
      expect(cachedPath, p.join(tempDir.path, 'file-1_remote.txt'));
      expect(cachedFile.existsSync(), isTrue);
      expect(await cachedFile.readAsBytes(), [1, 2, 3, 4]);
    });

    test('throws when remote attachment has no storageKey to download', () async {
      final repository = FakeTaskRepository(Uint8List(0));

      expect(
        () => downloadRemoteAttachmentToCache(
          const TaskAttachment(id: 'file-1', name: 'missing.txt', extension: 'txt', sizeBytes: 0),
          repository,
        ),
        throwsException,
      );
    });
  });
}

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository(this.bytes);

  final Uint8List bytes;
  final List<String> requestedStorageKeys = [];

  @override
  Future<void> addTask(Task task) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTask(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> getAttachmentBytes(String storageKey) async {
    requestedStorageKeys.add(storageKey);
    return bytes;
  }

  @override
  Future<void> syncTasks() {
    throw UnimplementedError();
  }

  @override
  Future<void> toggleTask(String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateTask(Task task) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Task>> watchTasks({
    required String searchQuery,
    required TaskFilterType filterType,
    required TaskSortType sortType,
    required TaskSortDirection sortDirection,
  }) {
    throw UnimplementedError();
  }
}
