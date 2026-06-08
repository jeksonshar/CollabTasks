import 'dart:io';

import 'package:collab_tasks/core/attachment_files/attachment_file_service.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';
import 'package:collab_tasks/features/tasks/domain/repositories/task_repository.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

const List<String> documentAttachmentExtensions = ['pdf', 'doc', 'docx', 'xml', 'txt'];

const Map<String, IconData> _extensionToIconMap = {
  'pdf': Icons.picture_as_pdf,
  'doc': Icons.description,
  'docx': Icons.description,
  'txt': Icons.description,
  'xml': Icons.code,
};

/// Обработчик скачивания/экспорта файла в память устройства
Future<void> handleDownloadAttachment({
  required BuildContext context,
  required TaskAttachment attachment,
  required AppLocalizations localization,
  required TaskRepository repository,
  VoidCallback? onStartLoading,
  VoidCallback? onEndLoading,
}) async {
  try {
    if (onStartLoading != null) onStartLoading();
    final saved = await downloadAttachmentFile(attachment, repository);
    debugPrint('handleDownloadAttachment() saved = $saved');

    if (!saved || !context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(localization.fileDownloaded)));
  } catch (e) {
    debugPrint('Failed to download file: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localization.fileDownloadError(e.toString()))));
    }
  } finally {
    if (onEndLoading != null) onEndLoading();
  }
}

IconData iconForExtension(String extension) {
  return _extensionToIconMap[extension.toLowerCase()] ?? Icons.insert_drive_file;
}

/// Обработчик просмотра файла (текстовый диалог или внешняя программа)
Future<void> handleViewAttachment({
  required BuildContext context,
  required TaskAttachment attachment,
  required AppLocalizations localization,
  required TaskRepository repository,
  VoidCallback? onStartLoading,
  VoidCallback? onEndLoading,
  // Для сохранения пути и размера в БД
  Future<void> Function(String newPath, int sizeBytes)? onCacheSynced,
}) async {
  try {
    TaskAttachment activeAttachment = attachment;

    // ВАЖНО: Если файл удаленный, сначала обеспечиваем его наличие в кэше.
    // Иначе tryReadTextAttachment() вернет null, так как файла нет на диске!
    String? finalPath = activeAttachment.localPath;
    if (finalPath == null || !File(finalPath).existsSync()) {
      if (activeAttachment.storageKey == null || activeAttachment.storageKey!.isEmpty) {
        throw Exception('Файл отсутствует локально и нет ключа для скачивания.');
      }

      // Сигнализируем UI, что загрузка началась
      if (onStartLoading != null) onStartLoading();

      try {
        // Скачиваем во временный кэш перед любым действием
        finalPath = await downloadRemoteAttachmentToCache(activeAttachment, repository);

        if (onCacheSynced != null) {
          // Получаем реальный размер скачанного файла с диска
          final fileLength = await File(finalPath).length();

          await onCacheSynced(finalPath, fileLength);
        }

        // Обновляем локальный путь в копии сущности для текущей сессии
        activeAttachment = activeAttachment.copyWith(localPath: finalPath);
      } finally {
        // Сигнализируем UI, что загрузка завершена (в блоке finally, чтоб сработало и при ошибке)
        if (onEndLoading != null) onEndLoading();
      }
    }

    // 1. Пытаемся прочитать как текст (теперь localPath гарантированно существует)
    final content = await tryReadTextAttachment(activeAttachment);

    if (content != null) {
      if (!context.mounted) return;
      await _showTextDialog(context, activeAttachment.name, content, localization);
      return;
    }

    // 2. Открываем файл через стороннее приложение
    if (!context.mounted) return;
    await openAttachment(activeAttachment);
  } catch (e) {
    debugPrint('Failed to view attachment: $e');
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(localization.fileOpenError(e))));
  }
}

// Приватный метод для показа текстового диалога
Future<void> _showTextDialog(
  BuildContext context,
  String title,
  String content,
  AppLocalizations localization,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: SelectableText(content, style: const TextStyle(fontFamily: 'monospace')),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(localization.cancel)),
      ],
    ),
  );
}
