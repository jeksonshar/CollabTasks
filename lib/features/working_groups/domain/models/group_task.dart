import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_subtask.dart';
import 'package:equatable/equatable.dart';

class GroupTask extends Equatable {
  const GroupTask({
    required this.id,
    required this.groupId,
    required this.createdAt,
    required this.title,
    required this.description,
    this.priority = 0,
    this.attachments = const [],
    this.subtasks = const [],
    this.isCompleted = false,
    this.deadline,
    this.isPinned = false,
    this.isSynced = false,
    this.assignedUserId,
    int? updatedAt,
  }) : updatedAt = updatedAt ?? 0;

  final String id;
  final String groupId;
  final DateTime createdAt;
  final String title;
  final String description;
  final int priority;
  final List<TaskAttachment> attachments;
  final List<TaskSubtask> subtasks;
  final bool isCompleted;
  final DateTime? deadline;
  final bool isPinned;
  final bool isSynced;
  final String? assignedUserId;
  final int updatedAt;

  GroupTask copyWith({
    String? id,
    String? groupId,
    DateTime? createdAt,
    String? title,
    String? description,
    int? priority,
    List<TaskAttachment>? attachments,
    List<TaskSubtask>? subtasks,
    bool? isCompleted,
    DateTime? deadline,
    bool? isPinned,
    bool? isSynced,
    Object? assignedUserId = _sentinel,
    int? updatedAt,
  }) {
    return GroupTask(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      attachments: attachments ?? List.from(this.attachments),
      subtasks: subtasks ?? List.from(this.subtasks),
      isCompleted: isCompleted ?? this.isCompleted,
      deadline: deadline ?? this.deadline,
      isPinned: isPinned ?? this.isPinned,
      isSynced: isSynced ?? this.isSynced,
      assignedUserId: assignedUserId == _sentinel ? this.assignedUserId : assignedUserId as String?,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Task toTask() {
    return Task(
      id: id,
      createdAt: createdAt,
      title: title,
      description: description,
      priority: priority,
      attachments: attachments,
      subtasks: subtasks,
      isCompleted: isCompleted,
      deadline: deadline,
      isPinned: isPinned,
      isSynced: isSynced,
      updatedAt: updatedAt,
    );
  }

  factory GroupTask.fromTask({
    required Task task,
    required String groupId,
    String? assignedUserId,
  }) {
    return GroupTask(
      id: task.id,
      groupId: groupId,
      createdAt: task.createdAt,
      title: task.title,
      description: task.description,
      priority: task.priority,
      attachments: task.attachments,
      subtasks: task.subtasks,
      isCompleted: task.isCompleted,
      deadline: task.deadline,
      isPinned: task.isPinned,
      isSynced: task.isSynced,
      assignedUserId: assignedUserId,
      updatedAt: task.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'title': title,
      'description': description,
      'priority': priority,
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'subtasks': subtasks.map((e) => e.toMap()).toList(),
      'isCompleted': isCompleted,
      'deadline': deadline?.millisecondsSinceEpoch,
      'isPinned': isPinned,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'assignedUserId': assignedUserId,
      'updatedAtMillis': updatedAt,
    };
  }

  factory GroupTask.fromMap(Map<String, dynamic> map) {
    final rawAttachments = map['attachments'] ?? map['files'];
    final rawSubtasks = map['subtasks'];
    return GroupTask(
      id: map['id'] as String,
      groupId: map['groupId'] as String? ?? '',
      createdAt: _dateTimeFromMillis(map['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      priority: _priorityFromRemote(map['priority']),
      attachments: rawAttachments is List
          ? rawAttachments
                .whereType<Map>()
                .map((item) => _attachmentFromMap(Map<String, dynamic>.from(item)))
                .toList(growable: false)
          : const [],
      subtasks: rawSubtasks is List
          ? rawSubtasks
                .whereType<Map>()
                .map((item) => TaskSubtask.fromMap(Map<String, dynamic>.from(item)))
                .toList(growable: false)
          : const [],
      isCompleted: map['isCompleted'] as bool? ?? false,
      deadline: _dateTimeFromMillis(map['deadline']),
      isPinned: map['isPinned'] as bool? ?? false,
      assignedUserId: map['assignedUserId'] as String?,
      updatedAt: (map['updatedAtMillis'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime? _dateTimeFromMillis(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    if (value is String) return DateTime.tryParse(value);
    return null;
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

  static TaskAttachment _attachmentFromMap(Map<String, dynamic> map) {
    final name = map['name'] as String? ?? '';
    return TaskAttachment(
      id: map['id'] as String? ?? '',
      name: name,
      extension: map['extension'] as String? ?? _extensionFromName(name),
      localPath: map['localPath'] as String?,
      storageKey: map['storageKey'] as String?,
      sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
    );
  }

  static String _extensionFromName(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) return '';
    return name.substring(dotIndex + 1);
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    createdAt,
    title,
    description,
    priority,
    attachments,
    subtasks,
    isCompleted,
    deadline,
    isPinned,
    isSynced,
    assignedUserId,
    updatedAt,
  ];
}

const Object _sentinel = Object();
