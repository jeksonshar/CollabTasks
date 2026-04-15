import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager/core/enums/task_sort_type.dart';
import 'package:task_manager/l10n/l10n_mixin.dart';

import '../../../core/enums/task_sort_direction.dart';
import '../../../domain/models/task_draft.dart';
import '../../../l10n/app_localizations.dart';
import '../../dialogs/task_dialog/task_dialog.dart';
import '../../view_models/task_view_model.dart';
import 'components/task_list_title.dart';
import 'components/task_rich_preview.dart';
import 'utils/json_helpers.dart';

class HomeTasksScreen extends StatefulWidget {
  const HomeTasksScreen({super.key});

  @override
  State<HomeTasksScreen> createState() => _HomeTasksScreenState();
}

class _HomeTasksScreenState extends State<HomeTasksScreen> with L10nMixin {
  late TaskViewModel vm;
  TaskErrorType? _lastShownError;

  @override
  void initState() {
    super.initState();
    // get the viewmodel in the next frame so that the context is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      vm = context.read<TaskViewModel>();
      vm.addListener(_onVmChanged);
      vm.loadTasks();
    });
  }

  void _onVmChanged() {
    if (!mounted) return;

    final errorType = vm.errorType;
    if (errorType == null || errorType == _lastShownError) return;

    _lastShownError = errorType;

    final message = switch (errorType) {
      TaskErrorType.load => localization.loadTasksError,
      TaskErrorType.add => localization.addTaskError,
      TaskErrorType.update => localization.updateTaskError,
      TaskErrorType.delete => localization.deleteTaskError,
    };

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

    vm.clearError();
    _lastShownError = null;
  }

  @override
  void dispose() {
    vm.removeListener(_onVmChanged);
    super.dispose();
  }

  Future<void> _showTaskDialog({int? editIndex}) async {
    final vm = context.read<TaskViewModel>();
    final initialTask = editIndex != null ? vm.tasks[editIndex] : null;

    final result = await showDialog<TaskDraft>(
      context: context,
      builder: (context) => TaskDialog(
        // flutter_quill dialog
        initialDeltaJson: initialTask?.text,
        initialPriority: initialTask?.priority ?? 0,
        initialAttachments: initialTask?.attachments ?? const [],
      ),
    );

    debugPrint('HomeTasksScreen AddTaskDialog result = $result');

    if (result == null || !mounted) return;

    final plain = deltaJsonToPlainText(result.textJson);

    if (editIndex == null) {
      // Adding a new task
      await vm.addTask(result);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localization.taskAdded(plain), maxLines: 3)));
    } else {
      // Editing an existing task
      final id = vm.tasks[editIndex].id;
      final createdAt = vm.tasks[editIndex].createdAt;
      await vm.updateTask(id, createdAt, result);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localization.taskUpdated(plain), maxLines: 3)));
    }
  }

  Future<void> _showDeleteDialog(int index) async {
    final vm = context.read<TaskViewModel>();
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.deleteTaskTitle),
        content: TaskRichPreview(deltaJson: vm.tasks[index].text),
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

    if (shouldDelete != true) return;

    final removed = vm.tasks[index];
    await vm.deleteTask(removed.id);

    if (vm.errorType == TaskErrorType.delete) return;

    final plain = deltaJsonToPlainText(removed.text);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(localization.taskDeleted(plain), maxLines: 3)));
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return Consumer<TaskViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(localization.my_tasks),
            scrolledUnderElevation: 0.0,
            // elevation: 12,
            centerTitle: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: PopupMenuButton<TaskSortType>(
                  icon: const Icon(Icons.sort),
                  initialValue: vm.sortType,
                  onSelected: vm.setSortType,
                  itemBuilder: (context) {
                    final localization = AppLocalizations.of(context)!;

                    return TaskSortType.values.map((type) {
                      final isSelected = vm.sortType == type;
                      final directionIcon = isSelected
                          ? vm.sortDirection.icon
                          : Icons.arrow_downward;

                      return PopupMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Expanded(child: Text(type.label(localization))),
                            const SizedBox(width: 12),
                            Icon(directionIcon, size: 18),
                          ],
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ],
          ),
          body: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : vm.tasks.isEmpty
              ? _emptyState()
              : _tasksListView(vm),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
            child: FloatingActionButton.extended(
              onPressed: _showTaskDialog,
              label: Text(localization.addTaskTitle),
              icon: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey),
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

  Widget _tasksListView(TaskViewModel vm) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: vm.tasks.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = vm.tasks[index];
        return TaskListTile(
          task: item,
          onTap: () => _showTaskDialog(editIndex: index),
          onLongPress: () => _showDeleteDialog(index),
        );
      },
    );
  }
}
