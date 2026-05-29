import 'dart:convert';

import 'package:equatable/equatable.dart';

class TaskSubtask extends Equatable {
  final String id;
  final String title;
  final bool isCompleted;

  const TaskSubtask({required this.id, required this.title, this.isCompleted = false});

  TaskSubtask copyWith({String? id, String? title, bool? isCompleted}) {
    return TaskSubtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'isCompleted': isCompleted};

  factory TaskSubtask.fromMap(Map<String, dynamic> map) {
    return TaskSubtask(
      id: map['id'] as String,
      title: map['title'] as String,
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, title, isCompleted];
}

class TaskSubtaskCodec {
  static String encodeList(List<TaskSubtask> items) {
    return jsonEncode(items.map((subtask) => subtask.toMap()).toList());
  }

  static List<TaskSubtask> decodeList(String? source) {
    if (source == null || source.isEmpty) {
      return const [];
    }

    final list = jsonDecode(source) as List<dynamic>;

    return list.whereType<Map<String, dynamic>>().map(TaskSubtask.fromMap).toList(growable: false);
  }
}
