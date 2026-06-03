import 'dart:convert';

import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_subtask.dart';
import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final String id;
  final DateTime createdAt;
  final String title;
  final String description;
  final int priority;
  final List<TaskAttachment> attachments;
  final List<TaskSubtask> subtasks;
  final bool isCompleted;
  final DateTime? deadline;
  final bool isPinned;
  final int updatedAt;

  const Task({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.description,
    this.priority = 0,
    this.attachments = const [],
    this.subtasks = const [],
    this.isCompleted = false,
    this.deadline,
    this.isPinned = false,
    int? updatedAt,
  }) : updatedAt = updatedAt ?? 0;

  Task copyWith({
    String? id,
    DateTime? createdAt,
    String? title,
    String? description,
    int? priority,
    List<TaskAttachment>? attachments,
    List<TaskSubtask>? subtasks,
    bool? isCompleted,
    DateTime? deadline,
    bool? isPinned,
    int? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      attachments: attachments ?? this.attachments,
      subtasks: subtasks ?? this.subtasks,
      isCompleted: isCompleted ?? this.isCompleted,
      deadline: deadline ?? this.deadline,
      isPinned: isPinned ?? this.isPinned,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'title': title,
    'description': description,
    'priority': priority,
    'attachments': attachments.map((e) => e.toJson()).toList(),
    'subtasks': subtasks.map((e) => e.toMap()).toList(),
    'isCompleted': isCompleted,
    'deadline': deadline?.toIso8601String(),
    'isPinned': isPinned,
    'updatedAt': updatedAt,
  };

  factory Task.fromMap(Map<String, dynamic> map) {
    final rawAttachments = map['attachments'];
    final rawSubtasks = map['subtasks'];

    return Task(
      id: map['id'] as String,
      createdAt: _parseRequiredDateTime(map['createdAt'], 'createdAt'),
      title: map['title'] as String,
      description: map['description'] as String,
      priority: map['priority'] as int,
      attachments: rawAttachments is List
          ? rawAttachments.whereType<Map<String, dynamic>>().map(TaskAttachment.fromJson).toList()
          : const [],
      subtasks: rawSubtasks is List
          ? rawSubtasks.whereType<Map<String, dynamic>>().map(TaskSubtask.fromMap).toList()
          : const [],
      isCompleted: map['isCompleted'] as bool? ?? false,
      deadline: _parseOptionalDateTime(map['deadline']),
      isPinned: map['isPinned'] as bool? ?? false,
      updatedAt: (map['updatedAt'] as num?)?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) => Task.fromMap(json.decode(source) as Map<String, dynamic>);

  static DateTime _parseRequiredDateTime(Object? value, String fieldName) {
    final parsed = _parseOptionalDateTime(value);
    if (parsed == null) {
      throw FormatException('Task.$fieldName is required and must be a DateTime value.');
    }
    return parsed;
  }

  static DateTime? _parseOptionalDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    throw FormatException('Unsupported DateTime value: $value');
  }

  @override
  List<Object?> get props => [
    id,
    createdAt,
    title,
    description,
    priority,
    attachments,
    subtasks,
    isCompleted,
    deadline,
    isPinned,
    updatedAt,
  ];
}
