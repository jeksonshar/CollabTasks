import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'task_attachment.dart';
import 'task_subtask.dart';

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
  });

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
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'createdAt': createdAt,
    'title': title,
    'description': description,
    'priority': priority,
    'attachments': attachments.map((e) => e.toJson()).toList(),
    'subtasks': subtasks.map((e) => e.toMap()).toList(),
    'isCompleted': isCompleted,
    'deadline': deadline?.toIso8601String(),
    'isPinned': isPinned,
  };

  factory Task.fromMap(Map<String, dynamic> map) {
    final rawAttachments = map['attachments'];
    final rawSubtasks = map['subtasks'];

    return Task(
      id: map['id'] as String,
      createdAt: map['createdAt'] as DateTime,
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
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline'] as String) : null,
      isPinned: map['isPinned'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) => Task.fromMap(json.decode(source) as Map<String, dynamic>);

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
  ];
}
