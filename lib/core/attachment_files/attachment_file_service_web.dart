import 'dart:js_interop';
import 'dart:typed_data';

import 'package:collab_tasks/domain/models/task_attachment.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:web/web.dart' as web;

import 'attachment_utils.dart';

Future<String?> attachmentsDirectory() async {
  return null;
}

Future<List<TaskAttachment>> pickAttachmentFiles(String? attachmentsDirPath) async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: documentAttachmentExtensions,
    withData: true,
  );

  if (result == null) return [];

  final newItems = <TaskAttachment>[];

  for (final file in result.files) {
    final originalName = file.name;
    final ext = (file.extension ?? p.extension(originalName).replaceFirst('.', '')).toLowerCase();
    final uniqueName = '${DateTime.now().microsecondsSinceEpoch}_$originalName'.replaceAll(
      '/',
      '_',
    );

    final bytes = file.bytes;
    if (bytes == null) continue;

    newItems.add(
      TaskAttachment(
        id: uniqueName,
        name: originalName,
        extension: ext,
        localPath: null,
        sizeBytes: bytes.length,
        bytes: bytes,
      ),
    );
  }

  return newItems;
}

String _mimeTypeForExtension(String extension) {
  switch (extension.toLowerCase()) {
    case 'pdf':
      return 'application/pdf';
    case 'txt':
      return 'text/plain; charset=utf-8';
    case 'xml':
      return 'application/xml; charset=utf-8';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    default:
      return 'application/octet-stream';
  }
}

web.Blob _createBlob(TaskAttachment attachment, Uint8List bytes) {
  final mimeType = _mimeTypeForExtension(attachment.extension);
  return web.Blob(<JSAny>[bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
}

Future<void> openAttachment(TaskAttachment attachment) async {
  final bytes = attachment.bytes;
  if (bytes == null) return;

  final blob = _createBlob(attachment, bytes);
  final url = web.URL.createObjectURL(blob);

  web.window.open(url, '_blank');

  Future.delayed(const Duration(seconds: 1), () {
    web.URL.revokeObjectURL(url);
  });
}

Future<String?> tryReadTextAttachment(TaskAttachment attachment) async {
  final ext = attachment.extension.toLowerCase();
  if (ext != 'xml' && ext != 'txt') return null;

  final bytes = attachment.bytes;
  if (bytes == null) return null;

  return String.fromCharCodes(bytes);
}

Future<bool> downloadAttachmentFile(TaskAttachment attachment) async {
  final bytes = attachment.bytes;
  if (bytes == null) return false;

  final blob = _createBlob(attachment, bytes);
  final url = web.URL.createObjectURL(blob);

  final _ = web.HTMLAnchorElement()
    ..href = url
    ..download = attachment.name
    ..click();

  Future.delayed(const Duration(seconds: 1), () {
    web.URL.revokeObjectURL(url);
  });

  return true;
}

Future<bool> removeAttachmentFile(TaskAttachment attachment) async {
  return true;
}
