import 'dart:io';
import 'dart:typed_data';

import 'package:collab_tasks/core/attachment_files/attachment_utils.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';
import 'package:collab_tasks/features/tasks/domain/repositories/task_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String?> attachmentsDirectory() async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'task_attachments'));

  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }

  return dir.path;
}

Future<List<TaskAttachment>> pickAttachmentFiles(String? attachmentsDirPath) async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: documentAttachmentExtensions,
  );

  if (files.isEmpty) return [];

  final newItems = <TaskAttachment>[];

  for (final file in files) {
    final originalName = file.name;
    final rawExt = p.extension(originalName).replaceFirst('.', '');
    final ext = rawExt.isNotEmpty ? rawExt.toLowerCase() : '';

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

  await OpenFile.open(path);
}

Future<String?> tryReadTextAttachment(TaskAttachment attachment) async {
  final ext = attachment.extension.toLowerCase();
  if (ext != 'xml' && ext != 'txt') return null;

  final path = attachment.localPath;
  if (path == null) return null;

  final file = File(path);
  return file.readAsString();
}

/// Метод сохранения файла на девайс (FilePicker)
Future<bool> downloadAttachmentFile(TaskAttachment attachment, TaskRepository repository) async {
  Uint8List bytes;

  try {
    if (attachment.localPath != null && File(attachment.localPath!).existsSync()) {
      bytes = await File(attachment.localPath!).readAsBytes();
    } else if (attachment.storageKey != null) {
      // Качаем через репозиторий
      final cachedPath = await downloadRemoteAttachmentToCache(attachment, repository);
      bytes = await File(cachedPath).readAsBytes();
    } else {
      return false;
    }

    // В v12 saveFile() вызвается статически и возвращает Uri?
    final Uri? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Сохранить файл',
      fileName: attachment.name,
      bytes: bytes,
    );

    return outputFile != null;
  } catch (e) {
    debugPrint('Ошибка при сохранении файла: $e');
    return false;
  }
}

/// Скачивает файл по storageKey во временный кэш девайса и возвращает локальный путь.
Future<String> downloadRemoteAttachmentToCache(
  TaskAttachment attachment,
  TaskRepository repository,
) async {
  if (attachment.storageKey == null || attachment.storageKey!.isEmpty) {
    throw Exception('Файл отсутствует локально и нет storageKey для скачивания');
  }
  debugPrint('downloadRemoteAttachmentToCache() not WEB');
  // 1. Качаем байты через SDK (вызывая репозиторий)
  final bytes = await repository.getAttachmentBytes(attachment.storageKey!);
  // 2. Сохраняем во временный кэш
  final tempDir = await getTemporaryDirectory();
  final cachePath = p.join(tempDir.path, '${attachment.id}_${attachment.name}');
  final file = File(cachePath);
  await file.writeAsBytes(bytes);

  return cachePath;
}

Future<bool> removeAttachmentFile(TaskAttachment attachment) async {
  try {
    final path = attachment.localPath;
    // Если пути нет, значит файл не скачивался на это устройство.
    // Удалять с диска нечего, но для UI это успешное "удаление".
    if (path == null) {
      debugPrint('removeAttachmentFile: localPath is null (remote file), skipping disk deletion.');
      return true;
    }

    final file = File(path);

    // Если файл не существует в кэше (например, операционка сама очистила temp директорию)
    // Тоже возвращаем true, так как подчищать за собой не нужно.
    if (!file.existsSync()) {
      debugPrint('removeAttachmentFile: file does not exist at $path, skipping disk deletion.');
      return true;
    }

    // Файл физически есть — удаляем
    await file.delete();
    debugPrint('Successfully removed attachment file from disk: $path');
    return true;
  } catch (e, s) {
    debugPrint('Error removing attachment file: $e\n$s');
    return false;
  }
}
