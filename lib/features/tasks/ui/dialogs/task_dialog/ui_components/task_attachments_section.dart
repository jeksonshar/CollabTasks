import 'package:collab_tasks/core/attachment_files/attachment_file_service.dart';
import 'package:collab_tasks/core/attachment_files/attachment_utils.dart';
import 'package:collab_tasks/core/theme/app_text_styles.dart';
import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';
import 'package:collab_tasks/features/tasks/domain/repositories/task_repository.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/confirmation_dialog_bloc/confirmation_dialog_bloc.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/confirmation_dialog_bloc/confirmation_dialog_event.dart';
import 'package:collab_tasks/features/tasks/ui/dialogs/confirmation_dialog.dart';
import 'package:collab_tasks/features/tasks/ui/dialogs/task_dialog/ui_components/task_attachment_tile.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:collab_tasks/l10n/l10n_mixin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  final Set<String> _loadingAttachmentIds = {};

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

  Future<void> _removeAttachment(TaskAttachment attachment) async {
    try {
      final isFileRemoved = await removeAttachmentFile(attachment);
      if (!mounted) return;

      if (!isFileRemoved) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(localization.deleteFileFailed),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      setState(() {
        _attachments.removeWhere((e) => e.id == attachment.id);
      });
      _notifyParent();

      if (mounted) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(localization.fileDeleted)));
      }
    } catch (e, s) {
      debugPrint('Error removing attachment: $e\n$s');
      if (!mounted) return;

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(localization.deleteFileFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showRemoveConfirmation(BuildContext context, TaskAttachment attachment) {
    final localization = AppLocalizations.of(context)!;

    // Get the ConfirmationDialogBloc from service locator
    final confirmationDialogBloc = getIt<ConfirmationDialogBloc>()
      // Initialize the dialog with appropriate text
      ..add(
        InitializeConfirmationDialog(
          title: localization.attentionTitle,
          message: localization.confirmDeleteFile(attachment.name),
          confirmButtonLabel: localization.delete,
          cancelButtonLabel: localization.cancel,
        ),
      );

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: confirmationDialogBloc,
        child: ConfirmationDialog(
          onConfirm: () {
            _removeAttachment(attachment);
          },
          onCancel: () {
            confirmationDialogBloc.add(const ResetConfirmationDialog());
          },
        ),
      ),
    ).then((_) {
      confirmationDialogBloc.add(const ResetConfirmationDialog());
    });
  }

  @override
  Widget build(BuildContext context) {
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
              child: Text(localization.attachFileTitle, style: AppTextStyles.bold16Roboto(context)),
            ),
            IconButton(onPressed: _pickAttachments, icon: const Icon(Icons.attach_file)),
          ],
        ),
        if (_attachments.isNotEmpty) ...[
          ..._attachments.map((attachment) {
            // проверяем, качается ли файл:
            final isLoading = _loadingAttachmentIds.contains(attachment.id);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TaskAttachmentTile(
                attachment: attachment,
                onView: () => handleViewAttachment(
                  context: context,
                  attachment: attachment,
                  localization: localization,
                  repository: getIt<TaskRepository>(),
                  onStartLoading: () {
                    setState(() => _loadingAttachmentIds.add(attachment.id));
                  },
                  onEndLoading: () {
                    setState(() => _loadingAttachmentIds.remove(attachment.id));
                  },
                  onCacheSynced: (newPath, sizeBytes) async {
                    // Находим индекс элемента, который только что скачался
                    final index = _attachments.indexWhere((e) => e.id == attachment.id);
                    if (index != -1) {
                      setState(() {
                        // Обновляем во внутренней копии списка
                        _attachments[index] = _attachments[index].copyWith(
                          localPath: newPath,
                          sizeBytes: sizeBytes,
                        );
                      });
                      // Уведомляем родительский экран (Диалог / Экран редактирования)
                      _notifyParent();
                    }
                  },
                ),
                onDownload: () => handleDownloadAttachment(
                  context: context,
                  attachment: attachment,
                  localization: localization,
                  repository: getIt<TaskRepository>(),
                  onStartLoading: () {
                    setState(() => _loadingAttachmentIds.add(attachment.id));
                  },
                  onEndLoading: () {
                    setState(() => _loadingAttachmentIds.remove(attachment.id));
                  },
                ),
                onDelete: () => _showRemoveConfirmation(context, attachment),
                isLoading: isLoading,
              ),
            );
          }),
        ],
      ],
    );
  }
}
