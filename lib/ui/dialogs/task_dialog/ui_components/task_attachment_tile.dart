import 'package:flutter/material.dart';

import '../../../../core/attachment_files/attachment_utils.dart';
import '../../../../domain/models/task_attachment.dart';
import '../../../../l10n/app_localizations.dart';

class TaskAttachmentTile extends StatelessWidget {
  final TaskAttachment attachment;
  final VoidCallback onView;

  // final VoidCallback onOpen;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const TaskAttachmentTile({
    super.key,
    required this.attachment,
    required this.onView,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final icon = iconForExtension(attachment.extension);
    final localization = AppLocalizations.of(context)!;

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(attachment.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${attachment.extension.toUpperCase()} • ${_formatBytes(attachment.sizeBytes, localization)}',
        ),
        onTap: onView,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                onView();
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
            PopupMenuItem(value: 'download', child: Text(localization.downloadFileTitle)),
            PopupMenuItem(value: 'delete', child: Text(localization.deleteFileTitle)),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes, AppLocalizations localization) {
    if (bytes < 1024) return '$bytes ${localization.bytesSuffixB}';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} ${localization.bytesSuffixKB}';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} ${localization.bytesSuffixMB}';
  }
}
