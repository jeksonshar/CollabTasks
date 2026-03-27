import 'dart:convert';

import 'task_attachment.dart';

class Task {
  final String id;
  final String text;
  final List<TaskAttachment> attachments;

  const Task({required this.id, required this.text, this.attachments = const []});

  Task copyWith({String? id, String? text, List<TaskAttachment>? attachments}) {
    return Task(
      id: id ?? this.id,
      text: text ?? this.text,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'attachments': attachments.map((e) => e.toJson()).toList(),
  };

  factory Task.fromMap(Map<String, dynamic> map) {
    final rawAttachments = map['attachments'];

    return Task(
      id: map['id'] as String,
      text: map['text'] as String,
      attachments: rawAttachments is List
          ? rawAttachments.whereType<Map<String, dynamic>>().map(TaskAttachment.fromJson).toList()
          : const [],
    );
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) => Task.fromMap(json.decode(source) as Map<String, dynamic>);
}
