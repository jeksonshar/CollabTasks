import 'package:collab_tasks/domain/models/task_attachment.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'attachment_file_service.dart';

const List<String> documentAttachmentExtensions = ['pdf', 'doc', 'docx', 'xml', 'txt'];

Future<void> handleDownloadAttachment({
  required BuildContext context,
  required TaskAttachment attachment,
  required AppLocalizations localization,
}) async {
  try {
    final saved = await downloadAttachmentFile(attachment);

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
  }
}

IconData iconForExtension(String extension) {
  switch (extension.toLowerCase()) {
    case 'pdf':
      return Icons.picture_as_pdf;
    case 'doc':
    case 'docx':
    case 'txt':
      return Icons.description;
    case 'xml':
      return Icons.code;
    default:
      return Icons.insert_drive_file;
  }
}

Future<void> handleViewAttachment({
  required BuildContext context,
  required TaskAttachment attachment,
  required AppLocalizations localization,
}) async {
  try {
    final content = await tryReadTextAttachment(attachment);

    if (content != null) {
      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(attachment.name),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: SelectableText(content, style: const TextStyle(fontFamily: 'monospace')),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(localization.cancel),
              ),
            ],
          );
        },
      );
      return;
    }

    await openAttachment(attachment);
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(localization.fileOpenError(e))));
  }
}
