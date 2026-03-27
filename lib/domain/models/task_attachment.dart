import 'dart:convert';

class TaskAttachment {
  final String id;
  final String name;
  final String extension;
  final String localPath;
  final int sizeBytes;

  const TaskAttachment({
    required this.id,
    required this.name,
    required this.extension,
    required this.localPath,
    required this.sizeBytes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'extension': extension,
    'localPath': localPath,
    'sizeBytes': sizeBytes,
  };

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    return TaskAttachment(
      id: json['id'] as String,
      name: json['name'] as String,
      extension: json['extension'] as String,
      localPath: json['localPath'] as String,
      sizeBytes: json['sizeBytes'] as int,
    );
  }

  static String encodeList(List<TaskAttachment> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }

  static List<TaskAttachment> decodeList(String? source) {
    if (source == null || source.isEmpty) return [];
    final list = jsonDecode(source) as List<dynamic>;
    return list.map((e) => TaskAttachment.fromJson(e as Map<String, dynamic>)).toList();
  }
}
