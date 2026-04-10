import 'package:flutter/material.dart';
import 'package:task_manager/domain/models/task.dart';

import 'task_rich_preview.dart';

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

  Color? _priorityColor(BuildContext context) {
    switch (task.priority) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      case 0:
        return null;
      default:
        return Theme.of(context).iconTheme.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey(task.id),
      leading: Icon(Icons.task_alt, color: _priorityColor(context)),
      title: TaskRichPreview(deltaJson: task.text),
      trailing: task.attachments.isNotEmpty ? const Icon(Icons.attach_file) : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
