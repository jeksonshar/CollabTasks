import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_subtask.dart';

class RemoteTaskMapper {
  const RemoteTaskMapper._();

  static Map<String, dynamic> toRemoteMap(Task task, {required String ownerId}) {
    return {
      'id': task.id,
      'ownerId': ownerId,
      'title': task.title,
      'description': task.description,
      'deadline': task.deadline?.millisecondsSinceEpoch,
      'isCompleted': task.isCompleted,
      'priority': _priorityToRemote(task.priority),
      'subtasks': task.subtasks.map(subtaskToRemoteMap).toList(growable: false),
      'files': task.attachments.map(fileToRemoteMap).toList(growable: false),
      'createdAt': task.createdAt.millisecondsSinceEpoch,
      'updatedAtMillis': task.updatedAt,
      'isPinned': task.isPinned,
    };
  }

  static Task fromRemoteMap(Map<String, dynamic> map) {
    final rawSubtasks = map['subtasks'];
    final rawFiles = map['files'] ?? map['attachments'];

    return Task(
      id: map['id'] as String,
      createdAt: _dateTimeFromMillis(map['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      deadline: _dateTimeFromMillis(map['deadline']),
      isCompleted: map['isCompleted'] as bool? ?? false,
      priority: _priorityFromRemote(map['priority']),
      subtasks: rawSubtasks is List
          ? rawSubtasks
                .whereType<Map>()
                .map((item) => subtaskFromRemoteMap(Map<String, dynamic>.from(item)))
                .toList(growable: false)
          : const [],
      attachments: rawFiles is List
          ? rawFiles
                .whereType<Map>()
                .map((item) => fileFromRemoteMap(Map<String, dynamic>.from(item)))
                .toList(growable: false)
          : const [],
      updatedAt: (map['updatedAtMillis'] as num?)?.toInt() ?? 0,
      isPinned: map['isPinned'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> subtaskToRemoteMap(TaskSubtask subtask) {
    return {'id': subtask.id, 'title': subtask.title, 'isCompleted': subtask.isCompleted};
  }

  static TaskSubtask subtaskFromRemoteMap(Map<String, dynamic> map) {
    return TaskSubtask(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> fileToRemoteMap(TaskAttachment file) {
    return {'id': file.id, 'name': file.name, 'storageKey': file.storageKey ?? ''};
  }

  static TaskAttachment fileFromRemoteMap(Map<String, dynamic> map) {
    final name = map['name'] as String? ?? '';
    return TaskAttachment(
      id: map['id'] as String,
      name: name,
      extension: _extensionFromName(name),
      storageKey: map['storageKey'] as String?,
      sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime? _dateTimeFromMillis(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    final seconds = _tryReadInt(value, 'seconds') ?? _tryReadInt(value, '_seconds');
    if (seconds != null) {
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    return null;
  }

  static String _priorityToRemote(int priority) {
    return switch (priority) {
      1 => 'low',
      2 => 'medium',
      3 => 'high',
      _ => 'none',
    };
  }

  static int _priorityFromRemote(Object? priority) {
    return switch (priority) {
      'low' => 1,
      'medium' => 2,
      'high' => 3,
      final int value => value,
      _ => 0,
    };
  }

  static int? _tryReadInt(Object value, String field) {
    if (value is! Map) {
      return null;
    }
    final raw = value[field];
    return raw is num ? raw.toInt() : null;
  }

  static String _extensionFromName(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) {
      return '';
    }
    return name.substring(dotIndex + 1);
  }
}
