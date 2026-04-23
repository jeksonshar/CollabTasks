import 'package:collab_tasks/domain/models/task.dart';
import 'package:flutter/material.dart';

import '../../../../core/task_priority/task_priority_utils.dart';
import '../../../../l10n/app_localizations.dart';

enum TaskMenuAction { pin, edit, delete }

class TaskListTile extends StatelessWidget {
  const TaskListTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onDelete,
    required this.onPinToggled,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onPinToggled;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final priority = TaskPriority.fromValue(task.priority);
    final priorityColor = priority.borderColor ?? Theme.of(context).iconTheme.color;

    final List<Widget> statusWidgets = [];

    if (task.isPinned) {
      if (statusWidgets.isNotEmpty) statusWidgets.add(const SizedBox(width: 4));
      statusWidgets.add(const Icon(Icons.push_pin, size: 16, color: Colors.black87));
    }

    if (task.deadline != null) {
      if (statusWidgets.isNotEmpty) statusWidgets.add(const SizedBox(width: 4));
      statusWidgets.add(const Icon(Icons.alarm, size: 16));
    }

    if (task.attachments.isNotEmpty) {
      statusWidgets.add(const Icon(Icons.attach_file, size: 16));
    }

    return ListTile(
      key: ValueKey(task.id),
      leading: task.isCompleted
          ? Icon(Icons.task_alt, color: priorityColor)
          : Icon(Icons.circle_outlined, color: priorityColor),
      title: Text(
        task.title,
        style: TextStyle(fontWeight: task.isPinned ? FontWeight.bold : FontWeight.normal),
      ),
      subtitle: statusWidgets.isNotEmpty
          ? Row(mainAxisSize: MainAxisSize.min, children: statusWidgets)
          : null,
      trailing: PopupMenuButton<TaskMenuAction>(
        icon: const Icon(Icons.more_vert),
        onSelected: (action) {
          switch (action) {
            case TaskMenuAction.pin:
              onPinToggled();
              break;
            case TaskMenuAction.edit:
              onTap();
              break;
            case TaskMenuAction.delete:
              onDelete();
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: TaskMenuAction.pin,
            child: Row(
              children: [
                Icon(task.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
                const SizedBox(width: 8),
                Text(task.isPinned ? localization.unpin : localization.pin),
              ],
            ),
          ),
          PopupMenuItem(
            value: TaskMenuAction.edit,
            child: Row(
              children: [const Icon(Icons.edit), const SizedBox(width: 8), Text(localization.edit)],
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
      onTap: onTap,
    );
  }
}
