import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:task_manager/l10n/l10n_mixin.dart';

import '../../../../core/attachment_file_service.dart';
import '../../../../domain/models/task_attachment.dart';
import 'task_attachment_tile.dart';

class TaskAttachmentsSection extends StatefulWidget {
  final List<TaskAttachment> initialAttachments;
  final ValueChanged<List<TaskAttachment>> onChanged;

  const TaskAttachmentsSection({
    super.key,
    required this.initialAttachments,
    required this.onChanged,
  });

  @override
  State<TaskAttachmentsSection> createState() => _TaskAttachmentsSectionState();
}

class _TaskAttachmentsSectionState extends State<TaskAttachmentsSection> with L10nMixin {
  late final List<TaskAttachment> _attachments = List<TaskAttachment>.of(widget.initialAttachments);

  @override
  void didUpdateWidget(covariant TaskAttachmentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!listEquals(oldWidget.initialAttachments, widget.initialAttachments)) {
      _attachments
        ..clear()
        ..addAll(widget.initialAttachments);
    }
  }

  void _notifyParent() {
    widget.onChanged(List.unmodifiable(_attachments));
  }

  Future<void> _pickAttachments() async {
    try {
      final attachmentsDirPath = await attachmentsDirectory();
      final newItems = await pickAttachmentFiles(attachmentsDirPath);

      if (!mounted || newItems.isEmpty) return;

      setState(() {
        _attachments.addAll(newItems);
      });
      _notifyParent();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(localization.taskAddedError(e))));
      debugPrint('Failed to pick attachments: $e');
    }
  }

  Future<void> _viewAttachment(TaskAttachment attachment) async {
    try {
      final content = await tryReadTextAttachment(attachment);

      if (content != null) {
        if (!mounted) return;

        showDialog<void>(
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
      if (!mounted) return;

      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(localization.fileOpenError(e))));
    }
  }

  Future<void> _downloadAttachment(TaskAttachment attachment) async {
    try {
      final saved = await downloadAttachmentFile(attachment);

      if (!saved || !mounted) return;

      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(localization.fileDownloaded)));
    } catch (e) {
      debugPrint('Не удалось скачать файл: $e');
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(localization.fileDownloadError(e))));
    }
  }

  Future<void> _removeAttachment(TaskAttachment attachment) async {
    setState(() {
      _attachments.removeWhere((e) => e.id == attachment.id);
    });
    _notifyParent();

    final isFileRemoved = await removeAttachmentFile(attachment);
    if (!mounted) return;

    if (!isFileRemoved) {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(localization.deleteFileFailed)));
    } else {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(localization.fileDeleted)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_attachments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Expanded() is necessary that the Text takes up only the available space
            // and does not push the IconButton beyond the Row.
            // It is necessary that the Text takes up only the available space and does not
            // push the IconButton beyond the Row.
            Expanded(
              child: Text(
                localization.attachFileTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: "Roboto",
                ),
              ),
            ),
            IconButton(onPressed: _pickAttachments, icon: const Icon(Icons.attach_file)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          localization.attachmentsTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: "Roboto",
          ),
        ),
        const SizedBox(height: 8),

        ..._attachments.map(
          (attachment) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TaskAttachmentTile(
              attachment: attachment,
              onView: () => _viewAttachment(attachment),
              onDownload: () => _downloadAttachment(attachment),
              onDelete: () => _removeAttachment(attachment),
            ),
          ),
        ),
      ],
    );
  }
}
