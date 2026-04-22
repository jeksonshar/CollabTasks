import 'package:collab_tasks/domain/models/task.dart';
import 'package:flutter/material.dart';

import '../../../../core/task_priority/task_priority_utils.dart';

class TaskListTile extends StatelessWidget {
  const TaskListTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onLongPress,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final priority = TaskPriority.fromValue(task.priority);
    final priorityColor = priority.borderColor ?? Theme.of(context).iconTheme.color;

    final List<Widget> trailingWidgets = [];

    if (task.attachments.isNotEmpty) {
      trailingWidgets.add(const Icon(Icons.attach_file));
    }

    if (task.deadline != null) {
      trailingWidgets.add(const Icon(Icons.alarm));
    }

    return ListTile(
      key: ValueKey(task.id),
      leading: task.isCompleted
          ? Icon(Icons.task_alt, color: priorityColor)
          : Icon(Icons.circle_outlined, color: priorityColor),
      title: Text(task.title),
      trailing: trailingWidgets.isNotEmpty
          ? Row(mainAxisSize: MainAxisSize.min, children: trailingWidgets)
          : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
