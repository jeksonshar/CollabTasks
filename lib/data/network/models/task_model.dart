import 'dart:convert';

import '../../../domain/models/task.dart';

// not used for now 5.02.26
class TaskModel extends Task {
  TaskModel({required super.id, required super.text, required super.createdAt});

  @override
  Map<String, dynamic> toMap() => {'id': id, 'text': text};

  factory TaskModel.fromMap(Map<String, dynamic> map) =>
      TaskModel(id: map['id'] as String, text: map['text'] as String, createdAt: map['createdAt']);

  @override
  String toJson() => json.encode(toMap());

  factory TaskModel.fromJson(String source) =>
      TaskModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
