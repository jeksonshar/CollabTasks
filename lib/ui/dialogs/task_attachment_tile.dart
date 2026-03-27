import 'package:flutter/material.dart';

import '../../domain/models/task_attachment.dart';
import '../../l10n/app_localizations.dart';

class TaskAttachmentTile extends StatelessWidget {
  final TaskAttachment attachment;
  final VoidCallback onView;
  final VoidCallback onOpen;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const TaskAttachmentTile({
    super.key,
    required this.attachment,
    required this.onView,
    required this.onOpen,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _iconForExtension(attachment.extension);
    final localization = AppLocalizations.of(context)!;

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(attachment.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${attachment.extension.toUpperCase()} • ${_formatBytes(attachment.sizeBytes)}',
        ),
        onTap: onView,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                onView();
                break;
              case 'open':
                onOpen();
                break;
              case 'download':
                onDownload();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'view', child: Text(localization.viewFileTitle)),
            // PopupMenuItem(value: 'open', child: Text(localization.openFileTitle)),
            PopupMenuItem(value: 'download', child: Text(localization.downloadFileTitle)),
            PopupMenuItem(value: 'delete', child: Text(localization.deleteFileTitle)),
          ],
        ),
      ),
    );
  }

  IconData _iconForExtension(String extension) {
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

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}
