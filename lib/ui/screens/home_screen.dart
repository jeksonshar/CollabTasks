import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dialogs/add_task_dialog.dart';
import '../view_models/task_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TaskViewModel vm;

  @override
  void initState() {
    super.initState();
    // get the viewmodel in the next frame so that the context is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      vm = Provider.of<TaskViewModel>(context, listen: false);
      vm.loadTasks();
    });
  }

  Future<void> _showAddTaskDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const AddTaskDialog(),
    );
    debugPrint('HomeScreen AddTaskDialog result = $result');
    if (result == null || result.trim().isEmpty) return;
    if (!mounted) return;
    await Provider.of<TaskViewModel>(context, listen: false).addTask(result.trim());
    debugPrint('HomeScreen AddTaskDialog result = $result');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Task added: "$result"')));
  }

  Future<void> _showDeleteDialog(int index) async {
    final vm = Provider.of<TaskViewModel>(context, listen: false);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete "${vm.tasks[index].text}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    final removed = vm.tasks[index];
    await vm.deleteTask(removed.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Deleted: "${removed.text}"')));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Home'), centerTitle: true),
          body: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : vm.tasks.isEmpty
              ? _emptyState()
              : _tasksListView(vm),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
            child: FloatingActionButton.extended(
              onPressed: _showAddTaskDialog,
              label: const Text('Add Task'),
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
      children: const [
        Icon(Icons.inbox, size: 64, color: Colors.grey),
        SizedBox(height: 12),
        Text('No tasks yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
        SizedBox(height: 4),
        Text('Tap "Add Task" to create one', style: TextStyle(color: Colors.grey)),
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
          title: Text(item.text),
          leading: const Icon(Icons.task_alt),
          onLongPress: () => _showDeleteDialog(index),
        );
      },
    );
  }
}
