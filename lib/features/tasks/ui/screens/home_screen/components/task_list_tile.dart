import 'package:collab_tasks/core/attachment_files/attachment_utils.dart';
import 'package:collab_tasks/core/task_priority/task_priority_utils.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/ui/screens/home_screen/components/task_rich_preview.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TaskMenuAction { pin, edit, delete }

class TaskListTile extends StatefulWidget {
  const TaskListTile({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onPinToggled,
    required this.expansionResetVersion,
    required this.forcedExpandedTaskId,
    required this.forcedExpansionVersion,
  });

  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPinToggled;
  final int expansionResetVersion;
  final String? forcedExpandedTaskId;
  final int forcedExpansionVersion;

  @override
  State<TaskListTile> createState() => _TaskListTileState();
}

class _TaskListTileState extends State<TaskListTile> {
  bool _isExpanded = false;

  bool get _isDeadlineOverdue {
    final deadline = widget.task.deadline;
    return deadline != null && deadline.isBefore(DateTime.now());
  }

  @override
  void initState() {
    super.initState();
    _isExpanded =
        widget.forcedExpansionVersion > 0 && widget.task.id == widget.forcedExpandedTaskId;
  }

  @override
  void didUpdateWidget(covariant TaskListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.forcedExpansionVersion != widget.forcedExpansionVersion) {
      setState(() {
        _isExpanded = widget.task.id == widget.forcedExpandedTaskId;
      });
      return;
    }

    if (oldWidget.expansionResetVersion != widget.expansionResetVersion && _isExpanded) {
      setState(() {
        _isExpanded = false;
      });
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final priority = TaskPriority.fromValue(widget.task.priority);
    final priorityColor = priority.borderColor ?? Theme.of(context).iconTheme.color;

    final List<Widget> statusWidgets = [];

    if (widget.task.isPinned) {
      if (statusWidgets.isNotEmpty) statusWidgets.add(const SizedBox(width: 4));
      statusWidgets.add(const Icon(Icons.push_pin, size: 16, color: Colors.black87));
    }

    if (widget.task.subtasks.isNotEmpty) {
      if (statusWidgets.isNotEmpty) statusWidgets.add(const SizedBox(width: 4));
      statusWidgets.add(const Icon(Icons.checklist, size: 16));
    }

    if (widget.task.deadline != null) {
      if (statusWidgets.isNotEmpty) statusWidgets.add(const SizedBox(width: 4));
      statusWidgets.add(Icon(Icons.alarm, size: 16, color: _isDeadlineOverdue ? Colors.red : null));
    }

    if (widget.task.attachments.isNotEmpty) {
      if (statusWidgets.isNotEmpty) statusWidgets.add(const SizedBox(width: 4));
      statusWidgets.add(const Icon(Icons.attach_file, size: 16));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              splashFactory: InkRipple.splashFactory,
              splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
              highlightColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
            ),
            child: ListTile(
              key: ValueKey(widget.task.id),
              leading: widget.task.isCompleted
                  ? Icon(Icons.task_alt, color: priorityColor)
                  : Icon(Icons.circle_outlined, color: priorityColor),
              title: Text(
                widget.task.title,
                style: TextStyle(
                  fontWeight: widget.task.isPinned ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: statusWidgets.isNotEmpty
                  ? Row(mainAxisSize: MainAxisSize.min, children: statusWidgets)
                  : null,
              trailing: PopupMenuButton<TaskMenuAction>(
                icon: const Icon(Icons.more_vert),
                onSelected: (action) {
                  switch (action) {
                    case TaskMenuAction.pin:
                      widget.onPinToggled();
                      break;
                    case TaskMenuAction.edit:
                      widget.onEdit();
                      break;
                    case TaskMenuAction.delete:
                      widget.onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: TaskMenuAction.pin,
                    child: Row(
                      children: [
                        Icon(widget.task.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
                        const SizedBox(width: 8),
                        Text(widget.task.isPinned ? localization.unpin : localization.pin),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: TaskMenuAction.edit,
                    child: Row(
                      children: [
                        const Icon(Icons.edit),
                        const SizedBox(width: 8),
                        Text(localization.edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: TaskMenuAction.delete,
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(localization.delete, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: _toggleExpanded,
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 460),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SizeTransition(sizeFactor: animation, axisAlignment: -1, child: child),
                  );
                },
                child: _isExpanded
                    ? _buildExpandedContent(context, localization)
                    : const SizedBox.shrink(key: ValueKey('collapsed')),
              ),
            ),
          ),
          // if (_isExpanded) _buildExpandedContent(context, localization),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, AppLocalizations localization) {
    return Padding(
      key: ValueKey(widget.task.id),
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TaskRichPreview(deltaJson: widget.task.description),
            ),
          ),
          if (widget.task.subtasks.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(localization.subtasksTitle, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...widget.task.subtasks.map(
              (subtask) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      subtask.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subtask.title,
                        style: TextStyle(
                          decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                          color: subtask.isCompleted ? Colors.black54 : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (widget.task.deadline != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.alarm, size: 18, color: _isDeadlineOverdue ? Colors.red : null),
                const SizedBox(width: 8),
                Text(
                  "${localization.deadlineTitle}: ${DateFormat.yMMMd(localization.localeName).add_jm().format(widget.task.deadline!)}",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
          if (widget.task.attachments.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(localization.attachmentsTitle, style: Theme.of(context).textTheme.titleSmall),
            ...widget.task.attachments.map(
              (attachment) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(iconForExtension(attachment.extension)),
                title: Text(attachment.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () => handleViewAttachment(
                        context: context,
                        attachment: attachment,
                        localization: localization,
                      ),
                      tooltip: localization.viewFileTitle,
                    ),
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => handleDownloadAttachment(
                        context: context,
                        attachment: attachment,
                        localization: localization,
                      ),
                      tooltip: localization.downloadFileTitle,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
