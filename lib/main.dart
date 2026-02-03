import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Tasks (dialog owns controller)',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _tasks = [];
  static const _tasksKey = 'tasks_list';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTasks = prefs.getStringList(_tasksKey);
    if (savedTasks != null) {
      setState(() => _tasks.addAll(savedTasks));
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_tasksKey, _tasks);
  }

  Future<void> _showAddTaskDialog() async {
    // show own dialog, which itself owns a controller
    final String? result = await showDialog<String>(
      context: context,
      // barrierDismissible true by default — tap out of dialog close it
      builder: (context) => const AddTaskDialog(),
    );

    if (result == null || result.isEmpty) return;
    if (!mounted) return; // safety check out of await

    setState(() => _tasks.add(result));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Task added: "$result"')));

    await _saveTasks();
  }

  Future<void> _showDeleteDialog(int index) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete task?'),
          content: Text('Delete "${_tasks[index]}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.black
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;
    if (!mounted) return;

    final removed = _tasks[index];
    setState(() => _tasks.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted: "$removed"')));

    await _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home'), centerTitle: true),
      body: _tasks.isEmpty ? _emptyState() : _tasksListView(),
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

  Widget _tasksListView() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _tasks.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _tasks[index];
        return ListTile(
          title: Text(item),
          leading: const Icon(Icons.task_alt),
          onLongPress: () => _showDeleteDialog(index),
        );
      },
    );
  }
}

/// Separate dialog StatefulWidget — it create and dispose TextEditingController
class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Task'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Enter task text'),
        onSubmitted: (value) {
          final trimmed = value.trim();
          if (trimmed.isNotEmpty) Navigator.of(context).pop(trimmed);
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),

        /// ValueListenableBuilder subscribes to the controller
        /// and automatically reconfigures the button state
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, child) {
            final enabled = value.text.trim().isNotEmpty;
            return ElevatedButton(
              onPressed: enabled ? () => Navigator.of(context).pop(_controller.text.trim()) : null,
              child: const Text('Enter'),
            );
          },
        ),
      ],
    );
  }
}
