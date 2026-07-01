import 'package:collab_tasks/core/theme/app_text_styles.dart';
import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/confirmation_dialog_bloc/confirmation_dialog_bloc.dart';
import 'package:collab_tasks/features/tasks/ui/blocs/confirmation_dialog_bloc/confirmation_dialog_event.dart';
import 'package:collab_tasks/features/tasks/ui/dialogs/confirmation_dialog.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:collab_tasks/l10n/l10n_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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

  Future<void> _selectDateTime() async {
    final current = _selectedDeadline ?? DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );

    if (pickedTime == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    final picked = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    if (picked != _selectedDeadline) {
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

  void _showRemoveConfirmation(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    // Get the ConfirmationDialogBloc from service locator
    final confirmationDialogBloc = getIt<ConfirmationDialogBloc>()
      // Initialize the dialog with appropriate text
      ..add(
        InitializeConfirmationDialog(
          title: localization.attentionTitle,
          message: localization.confirmDeleteDeadline,
          confirmButtonLabel: localization.delete,
          cancelButtonLabel: localization.cancel,
        ),
      );

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: confirmationDialogBloc,
        child: ConfirmationDialog(
          onConfirm: () {
            _clearDeadline();
          },
          onCancel: () {
            confirmationDialogBloc.add(const ResetConfirmationDialog());
          },
        ),
      ),
    ).then((_) {
      confirmationDialogBloc.add(const ResetConfirmationDialog());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(localization.deadlineTitle, style: AppTextStyles.bold16Roboto(context)),
        const SizedBox(width: 16),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: _selectDateTime,
              child: Text(
                _selectedDeadline == null
                    ? localization.setDeadline
                    : DateFormat.yMMMd(localization.localeName).add_jm().format(_selectedDeadline!),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        if (_selectedDeadline != null) ...[
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => _showRemoveConfirmation(context),
            tooltip: localization.clearDeadline,
          ),
        ],
      ],
    );
  }
}
