import 'package:collab_tasks/core/task_priority/task_priority_utils.dart';
import 'package:collab_tasks/core/theme/app_text_styles.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class TaskPrioritySection extends StatelessWidget {
  final TaskPriority priority;
  final ValueChanged<TaskPriority> onChanged;
  final String title;

  const TaskPrioritySection({
    super.key,
    required this.priority,
    required this.onChanged,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.bold16Roboto(context)),
        PopupMenuButton<TaskPriority>(
          tooltip: title,
          initialValue: priority,
          onSelected: onChanged,
          itemBuilder: (context) => TaskPriority.values
              .map(
                (item) => PopupMenuItem<TaskPriority>(
                  value: item,
                  child: Row(
                    children: [
                      Expanded(child: Text(item.label(localization))),
                      const SizedBox(width: 12),
                      _PriorityIndicator(item: item),
                    ],
                  ),
                ),
              )
              .toList(),
          child: _PriorityButton(selectedItem: priority),
        ),
      ],
    );
  }
}

class _PriorityButton extends StatelessWidget {
  final TaskPriority selectedItem;

  const _PriorityButton({required this.selectedItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.low_priority, size: 18, color: Theme.of(context).iconTheme.color),
          const SizedBox(width: 8),
          _PriorityIndicator(item: selectedItem),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}

class _PriorityIndicator extends StatelessWidget {
  final TaskPriority item;

  const _PriorityIndicator({required this.item});

  @override
  Widget build(BuildContext context) {
    final borderColor = item.borderColor ?? Theme.of(context).colorScheme.outline;

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: borderColor, width: 1.5),
        color: item.fillColor,
      ),
    );
  }
}
