import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/app_localizations.dart';

import '../blocs/confirmation_dialog_bloc/confirmation_dialog_bloc.dart';
import '../blocs/confirmation_dialog_bloc/confirmation_dialog_event.dart';
import '../blocs/confirmation_dialog_bloc/confirmation_dialog_state.dart';

/// Reusable delete confirmation dialog.
///
/// Customizable dialog to confirm any deletion actions.
/// Uses BLoC for state management.
///
/// Example of use:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => ConfirmationDialog(
///     onConfirm: () {
///       // execute deleting
///     },
///   ),
/// );
/// ```
class ConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final String? customTitle;
  final String? customMessage;
  final String? customConfirmLabel;
  final String? customCancelLabel;

  const ConfirmationDialog({
    super.key,
    required this.onConfirm,
    this.onCancel,
    this.customTitle,
    this.customMessage,
    this.customConfirmLabel,
    this.customCancelLabel,
  });

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return BlocListener<ConfirmationDialogBloc, ConfirmationDialogState>(
      listener: (context, state) {
        if (state.status == ConfirmationDialogStatus.confirmed) {
          Navigator.of(context).pop();
          onConfirm();
        } else if (state.status == ConfirmationDialogStatus.cancelled) {
          Navigator.of(context).pop();
          onCancel?.call();
        }
      },
      child: BlocBuilder<ConfirmationDialogBloc, ConfirmationDialogState>(
        builder: (context, state) {
          final title = customTitle ?? state.title;
          final message = customMessage ?? state.message;
          final confirmLabel = customConfirmLabel ?? state.confirmButtonLabel ?? localization.delete;
          final cancelLabel = customCancelLabel ?? state.cancelButtonLabel ?? localization.cancel;

          return AlertDialog(
            title: title != null && title.isNotEmpty ? Text(title) : null,
            content: message != null && message.isNotEmpty ? Text(message) : null,
            actions: [
              TextButton(
                onPressed: () {
                  context.read<ConfirmationDialogBloc>().add(const ConfirmationDialogCancelled());
                },
                child: Text(cancelLabel),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<ConfirmationDialogBloc>().add(const ConfirmationDialogConfirmed());
                },
                child: Text(confirmLabel),
              ),
            ],
          );
        },
      ),
    );
  }
}
