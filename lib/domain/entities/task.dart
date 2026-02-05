import 'dart:convert';

class Task {
  final String id;
  final String text;

  Task({required this.id, required this.text});

  Map<String, dynamic> toMap() => {'id': id, 'text': text};

  factory Task.fromMap(Map<String, dynamic> map) =>
      Task(id: map['id'] as String, text: map['text'] as String);

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) => Task.fromMap(json.decode(source) as Map<String, dynamic>);
}
