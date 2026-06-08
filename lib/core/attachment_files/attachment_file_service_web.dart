import 'dart:js_interop';
import 'dart:typed_data';

import 'package:collab_tasks/core/attachment_files/attachment_utils.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';
import 'package:collab_tasks/features/tasks/domain/repositories/task_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart' as web;

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
  final path = attachment.localPath;
  if (path == null) return;
  final uri = Uri.parse(path);

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw Exception('Could not launch $path');
  }
}

// Future<void> openAttachment(TaskAttachment attachment) async {
//   final bytes = attachment.bytes;
//   if (bytes == null) return;
//
//   final blob = _createBlob(attachment, bytes);
//   final url = web.URL.createObjectURL(blob);
//
//   web.window.open(url, '_blank');
//
//   Future.delayed(const Duration(seconds: 1), () {
//     web.URL.revokeObjectURL(url);
//   });
// }

Future<String?> tryReadTextAttachment(TaskAttachment attachment) async {
  final ext = attachment.extension.toLowerCase();
  if (ext != 'xml' && ext != 'txt') return null;

  final bytes = attachment.bytes;
  if (bytes == null) return null;

  return String.fromCharCodes(bytes);
}

Future<bool> downloadAttachmentFile(TaskAttachment attachment, TaskRepository repository) async {
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

Future<String> downloadRemoteAttachmentToCache(
  TaskAttachment attachment,
  TaskRepository repository,
) async {
  throw UnsupportedError('Кэширование файлов в файловую систему не поддерживается на Web');
}

// нужен настроенный CORS на сервере
// Future<String> downloadRemoteAttachmentToCache(
//     TaskAttachment attachment,
//     TaskRepository repository,
//     ) async {
//   if (attachment.storageKey == null || attachment.storageKey!.isEmpty) {
//     throw Exception('Файл отсутствует локально и нет storageKey для скачивания');
//   }
//
//   debugPrint('downloadRemoteAttachmentToCache() WEB');
//   // 1. Качаем байты через SDK (вызывая репозиторий)
//   final bytes = await repository.getAttachmentBytes(attachment.storageKey!);
//   debugPrint('downloadRemoteAttachmentToCache() WEB 1');
// // 1. Получаем Uint8List из байт
//   final u8List = bytes.buffer.asUint8List();
//
//   debugPrint('downloadRemoteAttachmentToCache() WEB 2');
//   // 2. Оборачиваем в JS-массив. Пакет web поймет u8List как BlobPart автоматически,
//   // если мы превратим сам List в JSArray с помощью расширения .toJS
//   final jsArray = [u8List.toJS].toJS;
//   debugPrint('downloadRemoteAttachmentToCache() WEB 3');
//   // 3. Создаем Blob
//   final blob = web.Blob(jsArray);
//   debugPrint('downloadRemoteAttachmentToCache() WEB 4');
//
//   final url = web.URL.createObjectURL(blob);
//   return url;
//   // throw UnsupportedError('Кэширование файлов в файловую систему не поддерживается на Web');
// }
