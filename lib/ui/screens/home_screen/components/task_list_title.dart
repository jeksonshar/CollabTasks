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

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey(task.id),
      leading: const Icon(Icons.task_alt),
      title: TaskRichPreview(deltaJson: task.text),
      trailing: task.attachments.isNotEmpty ? const Icon(Icons.attach_file) : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
