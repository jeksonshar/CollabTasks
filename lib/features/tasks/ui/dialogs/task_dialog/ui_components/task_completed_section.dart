import 'package:collab_tasks/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class TaskCompletedSection extends StatelessWidget {
  final bool isCompleted;
  final ValueChanged<bool> onChanged;
  final String title;

  const TaskCompletedSection({
    super.key,
    required this.isCompleted,
    required this.onChanged,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.bold16Roboto(context)),
        Checkbox(value: isCompleted, onChanged: (value) => onChanged(value ?? false)),
      ],
    );
  }
}
