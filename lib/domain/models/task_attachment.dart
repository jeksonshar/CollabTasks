import 'dart:convert';
import 'dart:typed_data';

class TaskAttachment {
  final String id;
  final String name;
  final String extension;
  final String? localPath; // путь к файлу (mobile/desktop)
  final int sizeBytes;
  final Uint8List? bytes; // бинарные данные (web)

  const TaskAttachment({
    required this.id,
    required this.name,
    required this.extension,
    required this.sizeBytes,
    this.localPath,
    this.bytes,
  });

  // удобно для проверки платформы
  bool get isWeb => bytes != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'extension': extension,
    'localPath': localPath,
    'sizeBytes': sizeBytes,

    //  bytes сохраняем только если есть (web)
    if (bytes != null) 'bytes': base64Encode(bytes!),
  };

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    return TaskAttachment(
      id: json['id'] as String,
      name: json['name'] as String,
      extension: json['extension'] as String,

      // старые данные продолжат работать
      localPath: json['localPath'] as String?,

      sizeBytes: json['sizeBytes'] as int,

      // web данные (если есть)
      bytes: json['bytes'] != null ? base64Decode(json['bytes'] as String) : null,
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
