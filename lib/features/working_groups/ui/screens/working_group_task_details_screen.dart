import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/tasks/ui/dialogs/task_dialog/task_dialog.dart';
import 'package:collab_tasks/features/tasks/ui/screens/home_screen/components/task_rich_preview.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_task_details/group_task_details_bloc.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_task_details/group_task_details_event.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_task_details/group_task_details_state.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class WorkingGroupTaskDetailsScreen extends StatelessWidget {
  const WorkingGroupTaskDetailsScreen({super.key, required this.task, required this.participants});

  final GroupTask task;
  final List<GroupParticipant> participants;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (_) => getIt<GroupTaskDetailsBloc>(param1: task),
      child: BlocConsumer<GroupTaskDetailsBloc, GroupTaskDetailsState>(
        listenWhen: (prev, current) => prev.status != current.status,
        listener: (context, state) {
          if (state.status == GroupTaskDetailsStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage ?? localization.group_task_details_defaultErrorMessage,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final currentTask = state.task;
          // Поиск исполнителя среди участников группы на основе актуального стейта задачи
          final currentAssignee = participants.cast<GroupParticipant?>().firstWhere(
            (p) => p?.userId == currentTask.assignedUserId,
            orElse: () => null,
          );

          debugPrint(
            'WorkingGroupTaskDetailsScreen build(): state.isAssignedToOther = ${state.isAssignedToOther}, state.isAssignedToMe = ${state.isAssignedToMe}',
          );

          return Scaffold(
            appBar: AppBar(
              title: Text(currentTask.title),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed:
                      state.isAssignedToOther || state.status == GroupTaskDetailsStatus.saving
                      ? null
                      : () => _showEditDialog(context, currentTask),
                ),
              ],
            ),
            body: Opacity(
              opacity: state.isAssignedToOther ? 0.55 : 1,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _AssignmentPanel(assignee: currentAssignee),
                  const SizedBox(height: 16),
                  Text(
                    localization.group_task_details_descriptionTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TaskRichPreview(deltaJson: currentTask.description),
                    ),
                  ),
                  if (currentTask.deadline != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      '${localization.group_task_details_deadlineTitle} ${DateFormat.yMMMd().add_jm().format(currentTask.deadline!)}',
                    ),
                  ],
                  if (currentTask.subtasks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      localization.group_task_details_subtasksTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ...currentTask.subtasks.map(
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
              child: _buildAssignmentButton(context, state, currentAssignee),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssignmentButton(
    BuildContext context,
    GroupTaskDetailsState state,
    GroupParticipant? assignee,
  ) {
    final isSaving = state.status == GroupTaskDetailsStatus.saving;
    final localization = AppLocalizations.of(context)!;

    // 1. Если задача ни на кого не назначена — показываем кнопку «Взять задачу»
    if (assignee == null) {
      return ElevatedButton.icon(
        onPressed: isSaving
            ? null
            : () => context.read<GroupTaskDetailsBloc>().add(const GroupTaskClaimRequested()),
        icon: const Icon(Icons.play_arrow),
        label: Text(localization.group_task_details_takeTaskBtn),
      );
    }

    // 2. Если задача назначена на ТЕКУЩЕГО пользователя (реактивный флаг из Блока)
    if (state.isAssignedToMe) {
      return OutlinedButton.icon(
        onPressed: isSaving
            ? null
            : () => context.read<GroupTaskDetailsBloc>().add(const GroupTaskReleaseRequested()),
        icon: const Icon(Icons.stop),
        label: Text(localization.group_task_details_releaseTask),
      );
    }

    // 3. Если задача назначена на КОГО-ТО ДРУГОГО (state.isAssignedToOther)
    return FilledButton.tonal(
      onPressed: null,
      child: Text(localization.group_task_details_taskInWork(assignee.name)),
    );
  }

  Future<void> _showEditDialog(BuildContext context, GroupTask currentTask) async {
    final bloc = context.read<GroupTaskDetailsBloc>();

    final draft = await showDialog(
      context: context,
      builder: (_) => TaskDialog(
        initialTitle: currentTask.title,
        initialDeltaJson: currentTask.description,
        initialAttachments: currentTask.attachments,
        initialPriority: currentTask.priority,
        initialIsCompletedState: currentTask.isCompleted,
        initialDeadline: currentTask.deadline,
        initialSubtasks: currentTask.subtasks,
      ),
    );

    if (!context.mounted) return;

    if (draft != null) {
      bloc.add(GroupTaskUpdateRequested(draft));
    }
  }
}

class _AssignmentPanel extends StatelessWidget {
  const _AssignmentPanel({required this.assignee});

  final GroupParticipant? assignee;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
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
                assignee == null
                    ? localization.group_task_details_taskFree
                    : localization.group_task_details_taskInWork(assignee!.name),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
