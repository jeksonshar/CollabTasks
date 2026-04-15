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

    return ListTile(
      key: ValueKey(task.id),
      leading: Icon(Icons.task_alt, color: priorityColor),
      title: Text(task.title),
      trailing: task.attachments.isNotEmpty ? const Icon(Icons.attach_file) : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
