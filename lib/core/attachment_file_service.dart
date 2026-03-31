import 'dart:io'; // только для web
import 'dart:js_interop';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:web/web.dart' as web;

import '../domain/models/task_attachment.dart';

// TODO 31.01 split this service into separate web and mobile/desktop services
Future<Directory?> attachmentsDirectory() async {
  if (kIsWeb) {
    return null;
  } else {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'task_attachments'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}

Future<List<TaskAttachment>> pickAttachmentFiles(Directory? attachmentsDir) async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: const ['pdf', 'doc', 'docx', 'xml', 'txt'],
    withData: true, // need for web
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

    if (kIsWeb) {
      // WEB
      final bytes = file.bytes;
      if (bytes == null) continue;
      newItems.add(
        TaskAttachment(
          id: uniqueName,
          name: originalName,
          extension: ext,
          localPath: '',
          // web contains empty path
          sizeBytes: bytes.length,
        ),
      );
    } else {
      // mobile / desktop
      final sourcePath = file.path;
      if (sourcePath == null || attachmentsDir == null) continue;

      final targetPath = p.join(attachmentsDir.path, uniqueName);
      final copied = await File(sourcePath).copy(targetPath);
      newItems.add(
        TaskAttachment(
          id: uniqueName,
          name: originalName,
          extension: ext,
          localPath: copied.path,
          sizeBytes: await copied.length(),
        ),
      );
    }
  }

  return newItems;
}

Future<void> openAttachment(TaskAttachment attachment) async {
  // TODO 27.03 не работает, bytes == null - разобраться
  if (kIsWeb) {
    final bytes = attachment.bytes;
    debugPrint('openAttachment: bytes = $bytes');
    if (bytes == null) return;

    final blob = web.Blob(<JSAny>[bytes.toJS].toJS);
    final url = web.URL.createObjectURL(blob);

    web.window.open(url, '_blank');

    Future.delayed(const Duration(seconds: 1), () {
      web.URL.revokeObjectURL(url);
    });
  } else {
    if (attachment.localPath == null) return;
    await OpenFilex.open(attachment.localPath!);
  }
}

Future<String?> tryReadTextAttachment(TaskAttachment attachment) async {
  final ext = attachment.extension.toLowerCase();
  if (ext != 'xml' && ext != 'txt') return null;

  if (kIsWeb) {
    final bytes = attachment.bytes;
    if (bytes == null) return null;

    return String.fromCharCodes(bytes);
  } else {
    if (attachment.localPath == null) return null;

    final file = File(attachment.localPath!);
    return file.readAsString();
  }
}

Future<bool> downloadAttachmentFile(TaskAttachment attachment) async {
  // TODO 27.03 не работает, bytes == null - разобраться
  if (kIsWeb) {
    final bytes = attachment.bytes;
    debugPrint('downloadAttachmentFile(): bytes = $bytes');
    if (bytes == null) return false;

    final blob = web.Blob(<JSAny>[bytes.toJS].toJS);
    final url = web.URL.createObjectURL(blob);

    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = attachment.name;

    anchor.click();

    Future.delayed(const Duration(seconds: 1), () {
      web.URL.revokeObjectURL(url);
    });
    return true;
  } else {
    if (attachment.localPath == null) return false;

    final bytes = await File(attachment.localPath!).readAsBytes();

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Сохранить файл',
      fileName: attachment.name,
      bytes: bytes,
    );

    return outputPath != null;
  }
}

Future<bool> removeAttachmentFile(TaskAttachment attachment) async {
  if (kIsWeb) {
    /// 🌐 файла физически нет
    return true;
  } else {
    try {
      if (attachment.localPath == null) return false;

      final file = File(attachment.localPath!);

      if (!await file.exists()) {
        return false;
      }

      await file.delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
