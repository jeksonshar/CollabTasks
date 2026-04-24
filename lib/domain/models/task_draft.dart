import 'package:collab_tasks/domain/models/task_attachment.dart';
import 'package:collab_tasks/domain/models/task_subtask.dart';

class TaskDraft {
  final String title;
  final String textJson;
  final int priority;
  final List<TaskAttachment> attachments;
  final List<TaskSubtask> subtasks;
  final bool isCompleted;
  final DateTime? deadline;

  const TaskDraft({
    required this.title,
    required this.textJson,
    required this.priority,
    required this.attachments,
    required this.subtasks,
    required this.isCompleted,
    this.deadline,
  });
}
