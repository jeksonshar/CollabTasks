import 'package:task_manager/domain/models/task_attachment.dart';

class TaskDraft {
  final String textJson;
  final int priority;
  final List<TaskAttachment> attachments;

  const TaskDraft({required this.textJson, required this.priority, required this.attachments});
}
