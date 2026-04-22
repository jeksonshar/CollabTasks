import 'package:collab_tasks/domain/models/task_attachment.dart';

class TaskDraft {
  final String title;
  final String textJson;
  final int priority;
  final List<TaskAttachment> attachments;
  final bool isCompleted;
  final DateTime? deadline;

  const TaskDraft({
    required this.title,
    required this.textJson,
    required this.priority,
    required this.attachments,
    required this.isCompleted,
    this.deadline,
  });
}
