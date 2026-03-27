import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import 'package:task_manager/l10n/l10n_mixin.dart';

import '../dialogs/task_dialog.dart';
import '../view_models/task_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with L10nMixin {
  late TaskViewModel vm;

  @override
  void initState() {
    super.initState();
    // get the viewmodel in the next frame so that the context is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      vm = Provider.of<TaskViewModel>(context, listen: false);
      // vm.loadTasks(); // TODO 27.03 it is not need seems like, check it
    });
  }

  Future<void> _showTaskDialog({int? editIndex}) async {
    final vm = Provider.of<TaskViewModel>(context, listen: false);
    final initialTask = editIndex != null ? vm.tasks[editIndex] : null;

    final result = await showDialog<TaskDialogResult>(
      context: context,
      builder: (context) => TaskDialog(
        // flutter_quill диалог
        initialDeltaJson: initialTask?.text,
        initialAttachments: initialTask?.attachments ?? const [],
      ),
    );

    debugPrint('HomeScreen AddTaskDialog result = $result');

    if (result == null) return;
    if (!mounted) return;

    final plain = _deltaJsonToPlainText(result.deltaJson);

    if (editIndex == null) {
      // Добавление новой задачи
      await vm.addTask(result);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localization.taskAdded(plain), maxLines: 3)));
    } else {
      // Редактирование существующей задачи
      final id = vm.tasks[editIndex].id;
      await vm.updateTask(id, result);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localization.taskUpdated(plain), maxLines: 3)));
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
        title: Text(localization.deleteTaskTitle),
        content: _buildTaskContent(vm.tasks[index].text),
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
    final plain = _deltaJsonToPlainText(removed.text);

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
        return ListTile(
          title: _buildTaskContent(item.text),
          leading: const Icon(Icons.task_alt),
          trailing: item.attachments.isNotEmpty ? const Icon(Icons.attach_file) : null,
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
