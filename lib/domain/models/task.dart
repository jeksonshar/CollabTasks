import 'dart:convert';

import 'task_attachment.dart';

class Task {
  final String id;
  final DateTime createdAt;
  final String text;
  final int priority;
  final List<TaskAttachment> attachments;

  const Task({
    required this.id,
    required this.createdAt,
    required this.text,
    this.priority = 0,
    this.attachments = const [],
  });

  Task copyWith({
    String? id,
    DateTime? createdAt,
    String? text,
    int? priority,
    List<TaskAttachment>? attachments,
  }) {
    return Task(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      text: text ?? this.text,
      priority: priority ?? this.priority,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'createdAt': createdAt,
    'text': text,
    'priority': priority,
    'attachments': attachments.map((e) => e.toJson()).toList(),
  };

  factory Task.fromMap(Map<String, dynamic> map) {
    final rawAttachments = map['attachments'];

    return Task(
      id: map['id'] as String,
      createdAt: map['createdAt'] as DateTime,
      text: map['text'] as String,
      priority: map['priority'] as int,
      attachments: rawAttachments is List
          ? rawAttachments.whereType<Map<String, dynamic>>().map(TaskAttachment.fromJson).toList()
          : const [],
    );
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) => Task.fromMap(json.decode(source) as Map<String, dynamic>);
}
