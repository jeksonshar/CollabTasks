import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import 'package:task_manager/l10n/app_localizations.dart';

import '../dialogs/add_task_dialog.dart';
import '../view_models/task_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TaskViewModel vm;
  late final loc = AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    // get the viewmodel in the next frame so that the context is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      vm = Provider.of<TaskViewModel>(context, listen: false);
      vm.loadTasks();
    });
  }

  Future<void> _showTaskDialog({int? editIndex}) async {
    final vm = Provider.of<TaskViewModel>(context, listen: false);
    final initial = editIndex != null ? vm.tasks[editIndex].text : null;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AddTaskDialog(
        // flutter_quill диалог
        initialDeltaJson: initial,
      ),
    );

    debugPrint('HomeScreen AddTaskDialog result = $result');

    if (result == null || result.trim().isEmpty) return;
    if (!mounted) return;

    final plain = _deltaJsonToPlainText(result);

    if (editIndex == null) {
      // Добавление новой задачи
      await vm.addTask(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.taskAdded(plain))));
    } else {
      // Редактирование существующей задачи
      final id = vm.tasks[editIndex].id;
      await vm.updateTask(id, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.taskUpdated(plain))));
    }
  }

  String _deltaJsonToPlainText(String deltaJson) {
    try {
      final doc = quill.Document.fromJson(jsonDecode(deltaJson) as List<dynamic>);
      return doc.toPlainText().trim();
    } catch (_) {
      return deltaJson;
    }
  }

  Future<void> _showDeleteDialog(int index) async {
    final vm = Provider.of<TaskViewModel>(context, listen: false);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteTaskTitle),
        content: _buildTaskContent(vm.tasks[index].text),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(loc.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    final removed = vm.tasks[index];

    await vm.deleteTask(removed.id);
    final plain = _deltaJsonToPlainText(removed.text);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.taskDeleted(plain))));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(title: Text(loc.home), centerTitle: true),
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
              label: Text(loc.addTaskTitle),
              icon: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inbox, size: 64, color: Colors.grey),
        SizedBox(height: 12),
        Text(loc.emptyTaskTitle, style: TextStyle(fontSize: 18, color: Colors.grey)),
        SizedBox(height: 4),
        Text(loc.emptyTaskDescription, style: TextStyle(color: Colors.grey)),
      ],
    ),
  );

  Widget _tasksListView(TaskViewModel vm) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: vm.tasks.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = vm.tasks[index];
        return ListTile(
          title: _buildTaskContent(item.text),
          leading: const Icon(Icons.task_alt),
          onLongPress: () => _showDeleteDialog(index),
          onTap: () => _showTaskDialog(editIndex: index),
        );
      },
    );
  }

  Widget _buildTaskContent(String deltaJson) {
    try {
      final document = quill.Document.fromJson(jsonDecode(deltaJson) as List<dynamic>);

      final controller = quill.QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );

      return IgnorePointer(
        // ignoring: true, // 👈 полностью отключает взаимодействие
        child: quill.QuillEditor(
          controller: controller,
          focusNode: FocusNode(canRequestFocus: false),
          scrollController: ScrollController(),
          config: const quill.QuillEditorConfig(
            expands: false,
            padding: EdgeInsets.zero,
            // enableInteractiveSelection: false, // 👈 убираем выделение
          ),
        ),
      );
    } catch (_) {
      return Text(deltaJson);
    }
  }
}
