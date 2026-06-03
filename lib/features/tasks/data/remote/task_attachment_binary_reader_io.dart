import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> readTaskAttachmentBytes(String? localPath) async {
  if (localPath == null || localPath.isEmpty) {
    return null;
  }
  return File(localPath).readAsBytes();
}
