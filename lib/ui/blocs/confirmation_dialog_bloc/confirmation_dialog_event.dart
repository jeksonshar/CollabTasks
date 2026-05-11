import 'package:equatable/equatable.dart';

abstract class ConfirmationDialogEvent extends Equatable {
  const ConfirmationDialogEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize the confirmation dialog
class InitializeConfirmationDialog extends ConfirmationDialogEvent {
  final String title;
  final String message;
  final String confirmButtonLabel;
  final String cancelButtonLabel;

  const InitializeConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmButtonLabel,
    required this.cancelButtonLabel,
  });

  @override
  List<Object?> get props => [title, message, confirmButtonLabel, cancelButtonLabel];
}

/// Event when the user confirms the action
class ConfirmationDialogConfirmed extends ConfirmationDialogEvent {
  const ConfirmationDialogConfirmed();
}

/// Event when the user cancels an action
class ConfirmationDialogCancelled extends ConfirmationDialogEvent {
  const ConfirmationDialogCancelled();
}

/// Event to clear the dialog state
class ResetConfirmationDialog extends ConfirmationDialogEvent {
  const ResetConfirmationDialog();
}
