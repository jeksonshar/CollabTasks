import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/models/task_subtask.dart';

class TaskSubtasksSection extends StatelessWidget {
  final List<TaskSubtask> subtasks;
  final ValueChanged<List<TaskSubtask>> onChanged;
  final bool canToggleCompletion;

  const TaskSubtasksSection({
    super.key,
    required this.subtasks,
    required this.onChanged,
    required this.canToggleCompletion,
  });

  void _addSubtask() {
    final item = TaskSubtask(id: DateTime.now().microsecondsSinceEpoch.toString(), title: '');
    onChanged([...subtasks, item]);
  }

  void _updateSubtask(TaskSubtask updated) {
    onChanged([
      for (final subtask in subtasks)
        if (subtask.id == updated.id) updated else subtask,
    ]);
  }

  void _removeSubtask(String id) {
    onChanged(subtasks.where((subtask) => subtask.id != id).toList(growable: false));
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(localization.subtasksTitle, style: AppTextStyles.bold16Black87Roboto),
            const Spacer(),
            TextButton.icon(
              onPressed: _addSubtask,
              icon: const Icon(Icons.add, size: 18),
              label: Text(localization.addSubtaskTitle),
            ),
          ],
        ),
        if (subtasks.isNotEmpty)
          ...subtasks.map(
            (subtask) => Padding(
              key: ValueKey(subtask.id),
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: subtask.isCompleted,
                    onChanged: canToggleCompletion
                        ? (value) {
                            _updateSubtask(subtask.copyWith(isCompleted: value ?? false));
                          }
                        : null,
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: subtask.title,
                      decoration: const InputDecoration(hintText: 'Subtask title', isDense: true),
                      onChanged: (value) => _updateSubtask(subtask.copyWith(title: value)),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeSubtask(subtask.id),
                    icon: const Icon(Icons.close),
                    tooltip: localization.removeSubtaskTitle,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
