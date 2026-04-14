import 'dart:convert';
import 'dart:typed_data';

class TaskAttachment {
  final String id;
  final String name;
  final String extension;
  final String? localPath; // path to file (mobile/desktop)
  final int sizeBytes;
  final Uint8List? bytes; // binary data (web)

  const TaskAttachment({
    required this.id,
    required this.name,
    required this.extension,
    required this.sizeBytes,
    this.localPath,
    this.bytes,
  });

  bool get isWeb => bytes != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'extension': extension,
    'localPath': localPath,
    'sizeBytes': sizeBytes,
    if (isWeb) 'bytesBase64': base64Encode(bytes!),
  };

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    final rawBytes = json['bytesBase64'] ?? json['bytes'];

    return TaskAttachment(
      id: json['id'] as String,
      name: json['name'] as String,
      extension: json['extension'] as String,

      // old data will continue to work
      localPath: json['localPath'] as String?,

      sizeBytes: (json['sizeBytes'] as num).toInt(),
      // web data (if available)
      bytes: rawBytes is String && rawBytes.isNotEmpty ? base64Decode(rawBytes) : null,
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
