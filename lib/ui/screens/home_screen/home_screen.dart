import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager/l10n/l10n_mixin.dart';
import 'package:task_manager/ui/screens/home_screen/utils/json_helpers.dart';

import '../../dialogs/task_dialog/task_dialog.dart';
import '../../view_models/task_view_model.dart';
import 'components/task_list_title.dart';
import 'components/task_rich_preview.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with L10nMixin {
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

    final result = await showDialog<TaskDialogResult>(
      context: context,
      builder: (context) => TaskDialog(
        // flutter_quill dialog
        initialDeltaJson: initialTask?.text,
        initialAttachments: initialTask?.attachments ?? const [],
      ),
    );

    debugPrint('HomeScreen AddTaskDialog result = $result');

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
      await vm.updateTask(id, result);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localization.taskUpdated(plain), maxLines: 3)));
    }
  }

  // String _deltaJsonToPlainText(String deltaJson) {
  //   try {
  //     final doc = quill.Document.fromJson(jsonDecode(deltaJson) as List<dynamic>);
  //     return doc.toPlainText().trim();
  //   } catch (_) {
  //     return deltaJson;
  //   }
  // }

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
    return Consumer<TaskViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(title: Text(localization.home), centerTitle: true),
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
          SizedBox(height: 12),
          Text(localization.emptyTaskTitle, style: TextStyle(fontSize: 18, color: Colors.grey)),
          SizedBox(height: 4),
          Text(localization.emptyTaskDescription, style: TextStyle(color: Colors.grey)),
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
