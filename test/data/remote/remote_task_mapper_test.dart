import 'package:collab_tasks/features/tasks/data/remote/remote_task_mapper.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_subtask.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteTaskMapper', () {
    test('serializes tasks to the shared remote format used by AWS and Firebase', () {
      final createdAt = DateTime.utc(2026, 6, 1, 10);
      final deadline = DateTime.utc(2026, 6, 2, 12, 30);
      final task = Task(
        id: 'task-1',
        createdAt: createdAt,
        title: 'Remote task',
        description: 'Stored remotely',
        deadline: deadline,
        priority: 3,
        isCompleted: true,
        isPinned: true,
        updatedAt: 12345,
        subtasks: const [TaskSubtask(id: 'subtask-1', title: 'Remote subtask', isCompleted: true)],
        attachments: const [
          TaskAttachment(
            id: 'file-1',
            name: 'report.pdf',
            extension: 'pdf',
            storageKey: 'users/user-1/tasks/task-1/files/file-1-report.pdf',
            sizeBytes: 2048,
          ),
        ],
      );

      final map = RemoteTaskMapper.toRemoteMap(task, ownerId: 'user-1');

      expect(map['id'], 'task-1');
      expect(map['ownerId'], 'user-1');
      expect(map['deadline'], deadline.millisecondsSinceEpoch);
      expect(map['createdAt'], createdAt.millisecondsSinceEpoch);
      expect(map['priority'], 'high');
      expect(map['updatedAtMillis'], 12345);
      expect(map['isPinned'], isTrue);
      expect(map['subtasks'], [
        {'id': 'subtask-1', 'title': 'Remote subtask', 'isCompleted': true},
      ]);
      expect(map['files'], [
        {
          'id': 'file-1',
          'name': 'report.pdf',
          'storageKey': 'users/user-1/tasks/task-1/files/file-1-report.pdf',
          'sizeBytes': 2048,
        },
      ]);
    });

    test('restores tasks from remote maps including attachment metadata', () {
      final task = RemoteTaskMapper.fromRemoteMap({
        'id': 'task-1',
        'createdAt': 1780317600000,
        'title': 'Remote task',
        'description': 'Stored remotely',
        'deadline': 1780417800000,
        'isCompleted': false,
        'priority': 'medium',
        'updatedAtMillis': 45678,
        'isPinned': true,
        'subtasks': [
          {'id': 'subtask-1', 'title': 'Remote subtask', 'isCompleted': true},
        ],
        'files': [
          {
            'id': 'file-1',
            'name': 'report.pdf',
            'storageKey': 'users/user-1/tasks/task-1/files/file-1-report.pdf',
            'sizeBytes': 2048,
          },
        ],
      });

      expect(task.id, 'task-1');
      expect(task.createdAt, DateTime.fromMillisecondsSinceEpoch(1780317600000));
      expect(task.deadline, DateTime.fromMillisecondsSinceEpoch(1780417800000));
      expect(task.priority, 2);
      expect(task.updatedAt, 45678);
      expect(task.isPinned, isTrue);
      expect(
        task.subtasks.single,
        const TaskSubtask(id: 'subtask-1', title: 'Remote subtask', isCompleted: true),
      );
      expect(task.attachments.single.name, 'report.pdf');
      expect(task.attachments.single.extension, 'pdf');
      expect(
        task.attachments.single.storageKey,
        'users/user-1/tasks/task-1/files/file-1-report.pdf',
      );
      expect(task.attachments.single.sizeBytes, 2048);
    });

    test('accepts legacy remote attachment field name', () {
      final task = RemoteTaskMapper.fromRemoteMap({
        'id': 'task-1',
        'createdAt': 0,
        'title': 'Legacy task',
        'description': '',
        'attachments': [
          {'id': 'file-1', 'name': 'legacy.txt', 'storageKey': 'legacy/key.txt'},
        ],
      });

      expect(task.attachments.single.name, 'legacy.txt');
      expect(task.attachments.single.extension, 'txt');
      expect(task.attachments.single.storageKey, 'legacy/key.txt');
    });
  });
}
