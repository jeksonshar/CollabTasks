import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Tasks',
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

  Future<void> _showAddTaskDialog() async {
    final controller = TextEditingController();

    // try { // finally block pass to crash
      final String? result = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Add Task'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Enter task text'),
              onSubmitted: (value) {
                final trimmed = value.trim();
                if (trimmed.isNotEmpty) Navigator.of(context).pop(trimmed);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  final enabled = value.text.trim().isNotEmpty;
                  return ElevatedButton(
                    onPressed: enabled
                        ? () => Navigator.of(context).pop(controller.text.trim())
                        : null,
                    child: const Text('Enter'),
                  );
                },
              ),
            ],
          );
        },
      );

      if (result == null || result.isEmpty) return;

      // early return if state mounted
      if (!mounted) return;

      setState(() {
        _tasks.add(result);
      });

      // Safe, checked state is mounted above
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task added: "$result"')),
      );
    // } finally { // it pass to crash
    //   controller.dispose();
    // }
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    // early return if state mounted
    if (!mounted) return;

    final removed = _tasks[index];
    setState(() {
      _tasks.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted: "$removed"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
      ),
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

  Widget _emptyState() {
    return Center(
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
  }

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
