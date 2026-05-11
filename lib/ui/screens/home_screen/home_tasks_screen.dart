import 'package:collab_tasks/core/enums/task_error_type.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/task.dart';
import '../../../domain/models/task_draft.dart';
import '../../blocs/task_bloc/task_bloc.dart';
import '../../blocs/task_bloc/task_event.dart';
import '../../blocs/task_bloc/task_state.dart';
import '../../dialogs/task_dialog/task_dialog.dart';
import 'components/task_app_bar_component.dart';
import 'components/task_fab_component.dart';
import 'components/task_list_tile.dart';

class HomeTasksScreen extends StatefulWidget {
  const HomeTasksScreen({super.key});

  @override
  State<HomeTasksScreen> createState() => _HomeTasksScreenState();
}

class _HomeTasksScreenState extends State<HomeTasksScreen> {
  int _expansionResetVersion = 0;
  int _forcedExpansionVersion = 0;
  String? _forcedExpandedTaskId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // ЛИСТЕНЕР ОШИБОК
        BlocListener<TaskBloc, TaskState>(
          listenWhen: (prev, curr) => prev.errorType != curr.errorType && curr.errorType != null,
          listener: (context, state) {
            final errorType = state.errorType;

            if (errorType == null) return;
            // Показываем SnackBar на ошибку
            final localization = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorType.label(localization)),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            context.read<TaskBloc>().add(ErrorCleared());
          },
        ),
        // ЛИСТЕНЕР УСПЕХА
        BlocListener<TaskBloc, TaskState>(
          listenWhen: (prev, curr) =>
              curr.lastAction != TaskAction.none && curr.lastActionTaskTitle != null,
          listener: (context, state) {
            final title = state.lastActionTaskTitle ?? '';
            final localization = AppLocalizations.of(context)!;
            late String message;

            switch (state.lastAction) {
              case TaskAction.add:
                message = localization.taskAdded(title);
                break;
              case TaskAction.update:
                message = localization.taskUpdated(title);
                break;
              case TaskAction.delete:
                message = localization.taskDeleted(title);
                break;
              default:
                return;
            }
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

            context.read<TaskBloc>().add(const ActionCleared());
          },
        ),
        BlocListener<TaskBloc, TaskState>(
          listenWhen: (prev, curr) =>
              prev.tasks != curr.tasks ||
              prev.sortType != curr.sortType ||
              prev.sortDirection != curr.sortDirection ||
              prev.filterType != curr.filterType ||
              prev.searchQuery != curr.searchQuery,
          listener: (context, state) {
            setState(() {
              _expansionResetVersion++;
            });
          },
        ),
        BlocListener<TaskBloc, TaskState>(
          listenWhen: (prev, curr) => prev.highlightedTaskVersion != curr.highlightedTaskVersion,
          listener: (context, state) {
            setState(() {
              _forcedExpandedTaskId = state.highlightedTaskId;
              _forcedExpansionVersion = state.highlightedTaskVersion;
              _expansionResetVersion++;
            });
          },
        ),
      ],
      child: Scaffold(
        appBar: const TasksAppBar(),
        body: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            if (state.status == TaskStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final filteredTasks = state.filteredTasks;

            if (filteredTasks.isEmpty) {
              return _emptyState(context);
            }
            return _tasksListView(filteredTasks);
          },
        ),
        floatingActionButtonLocation: fabLocation,
        floatingActionButton: AddTaskFab(
          onPressed: () {
            _showTaskDialog(context);
          },
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            localization.emptyTaskTitle,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(localization.emptyTaskDescription, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _tasksListView(List<Task> tasks) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tasks.length,
      // separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = tasks[index];
        return TaskListTile(
          key: ValueKey(item.id),
          task: item,
          onEdit: () => _showTaskDialog(context, taskToEdit: item),
          onDelete: () => _showDeleteDialog(context, item),
          onPinToggled: () => context.read<TaskBloc>().add(TaskPinToggled(item.id)),
          expansionResetVersion: _expansionResetVersion,
          forcedExpandedTaskId: _forcedExpandedTaskId,
          forcedExpansionVersion: _forcedExpansionVersion,
        );
      },
    );
  }

  Future<void> _showTaskDialog(BuildContext context, {dynamic taskToEdit}) async {
    final bloc = context.read<TaskBloc>();

    final result = await showDialog<TaskDraft>(
      context: context,
      builder: (context) => TaskDialog(
        // flutter_quill dialog
        initialTitle: taskToEdit?.title,
        initialDeltaJson: taskToEdit?.text,
        initialPriority: taskToEdit?.priority ?? 0,
        initialAttachments: taskToEdit?.attachments ?? const [],
        initialSubtasks: taskToEdit?.subtasks ?? const [],
        initialIsCompletedState: taskToEdit?.isCompleted ?? false,
        initialDeadline: taskToEdit?.deadline,
      ),
    );

    debugPrint('HomeTasksScreen AddTaskDialog result = $result');

    if (result == null || !context.mounted) return;

    if (taskToEdit == null) {
      bloc.add(TaskAdded(result));
    } else {
      bloc.add(TaskUpdated(taskToEdit.id, taskToEdit.createdAt, result));
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, dynamic taskToRemove) async {
    final bloc = context.read<TaskBloc>();
    final localization = AppLocalizations.of(context)!;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.deleteTaskTitle),
        content: Text(taskToRemove.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localization.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(localization.delete),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !context.mounted) return;

    bloc.add(TaskDeleted(taskToRemove.id));
  }
}
