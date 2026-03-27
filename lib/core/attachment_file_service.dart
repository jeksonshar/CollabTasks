import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/models/task_attachment.dart';

Future<Directory> attachmentsDirectory() async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'task_attachments'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

Future<List<TaskAttachment>> pickAttachmentFiles(Directory attachmentsDir) async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: const ['pdf', 'doc', 'docx', 'xml', 'txt'],
  );

  if (result == null) return [];

  final newItems = <TaskAttachment>[];

  for (final file in result.files) {
    final sourcePath = file.path;
    if (sourcePath == null) continue;

    final originalName = file.name;
    final ext = (file.extension ?? p.extension(originalName).replaceFirst('.', '')).toLowerCase();

    final uniqueName = '${DateTime.now().microsecondsSinceEpoch}_$originalName'.replaceAll(
      '/',
      '_',
    );
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

  return newItems;
}

Future<void> openAttachment(TaskAttachment attachment) async {
  debugPrint('openAttachment: ${attachment.localPath}');
  await OpenFilex.open(attachment.localPath);
}

Future<String?> tryReadTextAttachment(TaskAttachment attachment) async {
  final ext = attachment.extension.toLowerCase();
  if (ext != 'xml' && ext != 'txt') return null;

  final file = File(attachment.localPath);
  return file.readAsString();
}

Future<bool> downloadAttachmentFile(TaskAttachment attachment) async {
  final bytes = await File(attachment.localPath).readAsBytes();

  final outputPath = await FilePicker.platform.saveFile(
    dialogTitle: 'Сохранить файл',
    fileName: attachment.name,
    bytes: bytes,
  );

  return outputPath != null;
}

Future<bool> removeAttachmentFile(TaskAttachment attachment) async {
  try {
    final file = File(attachment.localPath);

    if (!await file.exists()) {
      return false;
    }
    await file.delete();
    return true;
  } catch (_) {
    return false;
    // best-effort: если файл не удалился, UI всё равно может убрать его из списка
  }
}
