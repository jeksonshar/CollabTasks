import 'dart:io';

import 'package:collab_tasks/domain/models/task_attachment.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'attachment_utils.dart';

Future<String?> attachmentsDirectory() async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'task_attachments'));

  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }

  return dir.path;
}

Future<List<TaskAttachment>> pickAttachmentFiles(String? attachmentsDirPath) async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: documentAttachmentExtensions,
    withData: false,
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

    final sourcePath = file.path;
    if (sourcePath == null || attachmentsDirPath == null) continue;

    final targetPath = p.join(attachmentsDirPath, uniqueName);
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
  final path = attachment.localPath;
  if (path == null) return;

  await OpenFilex.open(path);
}

Future<String?> tryReadTextAttachment(TaskAttachment attachment) async {
  final ext = attachment.extension.toLowerCase();
  if (ext != 'xml' && ext != 'txt') return null;

  final path = attachment.localPath;
  if (path == null) return null;

  final file = File(path);
  return file.readAsString();
}

Future<bool> downloadAttachmentFile(TaskAttachment attachment) async {
  final path = attachment.localPath;
  if (path == null) return false;

  final bytes = await File(path).readAsBytes();

  final outputPath = await FilePicker.platform.saveFile(
    dialogTitle: 'Сохранить файл',
    fileName: attachment.name,
    bytes: bytes,
  );

  return outputPath != null;
}

Future<bool> removeAttachmentFile(TaskAttachment attachment) async {
  try {
    final path = attachment.localPath;
    if (path == null) {
      debugPrint('Cannot remove attachment: localPath is null');
      return false;
    }

    final file = File(path);

    if (!file.existsSync()) {
      debugPrint('Cannot remove attachment: file does not exist at $path');
      return false;
    }

    await file.delete();
    debugPrint('Successfully removed attachment file: $path');
    return true;
  } catch (e, s) {
    debugPrint('Error removing attachment file: $e\n$s');
    return false;
  }
}
