import 'package:flutter/material.dart';
import 'package:task_manager/core/theme/app_text_styles.dart';

class TaskPrioritySection extends StatelessWidget {
  final int priority;
  final ValueChanged<int> onChanged;
  final String title;

  const TaskPrioritySection({
    super.key,
    required this.priority,
    required this.onChanged,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final selectedItem = _PriorityItem.byValue(priority);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.bold16Black87Roboto),
        PopupMenuButton<int>(
          tooltip: title,
          initialValue: priority,
          onSelected: onChanged,
          itemBuilder: (context) => _PriorityItem.values
              .map(
                (item) => PopupMenuItem<int>(
                  value: item.value,
                  child: Row(
                    children: [
                      Expanded(child: Text(item.label)),
                      const SizedBox(width: 12),
                      _PriorityIndicator(item: item),
                    ],
                  ),
                ),
              )
              .toList(),
          child: _PriorityButton(selectedItem: selectedItem),
        ),
      ],
    );
  }
}

class _PriorityButton extends StatelessWidget {
  final _PriorityItem selectedItem;

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
  final _PriorityItem item;

  const _PriorityIndicator({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: item.color ?? Theme.of(context).colorScheme.outline, width: 1.5),
        color: item.fillColor,
      ),
    );
  }
}

class _PriorityItem {
  final int value;
  final String label;
  final Color? color;
  final Color? fillColor;

  const _PriorityItem({
    required this.value,
    required this.label,
    required this.color,
    required this.fillColor,
  });

  static const values = <_PriorityItem>[
    _PriorityItem(value: 0, label: 'Без приоритета', color: null, fillColor: null),
    _PriorityItem(
      value: 1,
      label: 'Низкий приоритет',
      color: Colors.green,
      fillColor: Color(0x332E7D32),
    ),
    _PriorityItem(
      value: 2,
      label: 'Средний приоритет',
      color: Colors.amber,
      fillColor: Color(0x33FFB300),
    ),
    _PriorityItem(
      value: 3,
      label: 'Высокий приоритет',
      color: Colors.red,
      fillColor: Color(0x33C62828),
    ),
  ];

  static _PriorityItem byValue(int value) {
    return values.firstWhere((e) => e.value == value, orElse: () => values.first);
  }
}
