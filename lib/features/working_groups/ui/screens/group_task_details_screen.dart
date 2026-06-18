import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/tasks/ui/dialogs/task_dialog/task_dialog.dart';
import 'package:collab_tasks/features/tasks/ui/screens/home_screen/components/task_rich_preview.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/group_task_details/group_task_details_bloc.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/group_task_details/group_task_details_event.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/group_task_details/group_task_details_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class GroupTaskDetailsScreen extends StatelessWidget {
  const GroupTaskDetailsScreen({
    super.key,
    required this.task,
    required this.assignee,
    required this.currentUserId,
    required this.participants,
  });

  final GroupTask task;
  final GroupParticipant? assignee;
  final String? currentUserId;
  final List<GroupParticipant> participants;

  bool get _isAssignedToCurrentUser => assignee != null && assignee!.userId == currentUserId;

  bool get _isAssignedToOther => assignee != null && assignee!.userId != currentUserId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GroupTaskDetailsBloc>(param1: task),
      child: BlocConsumer<GroupTaskDetailsBloc, GroupTaskDetailsState>(
        listener: (context, state) {
          if (state.status == GroupTaskDetailsStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Ошибка обновления задачи')),
            );
          }
          if (state.status == GroupTaskDetailsStatus.success) {
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(task.title),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _isAssignedToOther || state.status == GroupTaskDetailsStatus.saving
                      ? null
                      : () => _showEditDialog(context),
                ),
              ],
            ),
            body: Opacity(
              opacity: _isAssignedToOther ? 0.55 : 1,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _AssignmentPanel(task: task, assignee: assignee),
                  const SizedBox(height: 16),
                  Text('Описание', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TaskRichPreview(deltaJson: task.description),
                    ),
                  ),
                  if (task.deadline != null) ...[
                    const SizedBox(height: 16),
                    Text('Срок: ${DateFormat.yMMMd().add_jm().format(task.deadline!)}'),
                  ],
                  if (task.subtasks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Подзадачи', style: Theme.of(context).textTheme.titleMedium),
                    ...task.subtasks.map(
                      (subtask) => CheckboxListTile(
                        value: subtask.isCompleted,
                        onChanged: null,
                        title: Text(subtask.title),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildAssignmentButton(context, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssignmentButton(BuildContext context, GroupTaskDetailsState state) {
    final isSaving = state.status == GroupTaskDetailsStatus.saving;
    if (assignee == null) {
      return ElevatedButton.icon(
        onPressed: isSaving
            ? null
            : () => context.read<GroupTaskDetailsBloc>().add(const GroupTaskClaimRequested()),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Взять задачу'),
      );
    }
    if (_isAssignedToCurrentUser) {
      return OutlinedButton.icon(
        onPressed: isSaving
            ? null
            : () => context.read<GroupTaskDetailsBloc>().add(const GroupTaskReleaseRequested()),
        icon: const Icon(Icons.stop),
        label: const Text('Освободить задачу'),
      );
    }
    return FilledButton.tonal(onPressed: null, child: Text('В работе у ${assignee!.name}'));
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final bloc = context.read<GroupTaskDetailsBloc>();
    final draft = await showDialog(
      context: context,
      builder: (_) => TaskDialog(
        initialTitle: task.title,
        initialDeltaJson: task.description,
        initialAttachments: task.attachments,
        initialPriority: task.priority,
        initialIsCompletedState: task.isCompleted,
        initialDeadline: task.deadline,
        initialSubtasks: task.subtasks,
      ),
    );
    if (draft != null) {
      bloc.add(GroupTaskUpdateRequested(draft));
    }
  }
}

class _AssignmentPanel extends StatelessWidget {
  const _AssignmentPanel({required this.task, required this.assignee});

  final GroupTask task;
  final GroupParticipant? assignee;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: assignee == null ? colorScheme.secondaryContainer : colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(assignee == null ? Icons.lock_open : Icons.engineering),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                assignee == null ? 'Свободно' : 'В работе у ${assignee!.name}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
