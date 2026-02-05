import 'package:flutter/material.dart';

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
