import 'package:collab_tasks/l10n/l10n_mixin.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_text_styles.dart';

class TaskDeadlineSection extends StatefulWidget {
  final DateTime? initialDeadline;
  final ValueChanged<DateTime?> onChanged;

  const TaskDeadlineSection({super.key, required this.initialDeadline, required this.onChanged});

  @override
  State<TaskDeadlineSection> createState() => _TaskDeadlineSectionState();
}

class _TaskDeadlineSectionState extends State<TaskDeadlineSection> with L10nMixin {
  DateTime? _selectedDeadline;

  @override
  void initState() {
    super.initState();
    _selectedDeadline = widget.initialDeadline;
  }

  @override
  void didUpdateWidget(covariant TaskDeadlineSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDeadline != widget.initialDeadline) {
      _selectedDeadline = widget.initialDeadline;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
      });
      widget.onChanged(picked);
    }
  }

  void _clearDeadline() {
    setState(() {
      _selectedDeadline = null;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(localization.deadlineTitle, style: AppTextStyles.bold16Black87Roboto),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _selectDate(context),
                child: Text(
                  _selectedDeadline == null
                      ? localization.setDeadline
                      : DateFormat.yMMMd(localization.localeName).format(_selectedDeadline!),
                ),
              ),
            ),
            if (_selectedDeadline != null) ...[
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearDeadline,
                tooltip: localization.clearDeadline,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
