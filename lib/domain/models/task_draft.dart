import 'package:collab_tasks/domain/models/task_attachment.dart';
import 'package:collab_tasks/domain/models/task_subtask.dart';

class TaskDraft {
  final String title;
  final String descriptionJson;
  final int priority;
  final List<TaskAttachment> attachments;
  final List<TaskSubtask> subtasks;
  final bool isCompleted;
  final DateTime? deadline;

  const TaskDraft({
    required this.title,
    required this.descriptionJson,
    required this.priority,
    required this.attachments,
    required this.subtasks,
    required this.isCompleted,
    this.deadline,
  });

  TaskDraft copyWith({
    String? title,
    String? descriptionJson,
    int? priority,
    List<TaskAttachment>? attachments,
    List<TaskSubtask>? subtasks,
    bool? isCompleted,
    DateTime? deadline,
  }) {
    return TaskDraft(
      title: title ?? this.title,
      descriptionJson: descriptionJson ?? this.descriptionJson,
      priority: priority ?? this.priority,
      attachments: attachments ?? this.attachments,
      subtasks: subtasks ?? this.subtasks,
      isCompleted: isCompleted ?? this.isCompleted,
      deadline: deadline ?? this.deadline,
    );
  }
}
