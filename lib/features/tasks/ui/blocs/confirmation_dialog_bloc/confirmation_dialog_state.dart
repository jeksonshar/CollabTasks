import 'package:equatable/equatable.dart';

enum ConfirmationDialogStatus { initial, pending, confirmed, cancelled }

class ConfirmationDialogState extends Equatable {
  final ConfirmationDialogStatus status;
  final String? title;
  final String? message;
  final String? confirmButtonLabel;
  final String? cancelButtonLabel;

  const ConfirmationDialogState({
    this.status = ConfirmationDialogStatus.initial,
    this.title,
    this.message,
    this.confirmButtonLabel,
    this.cancelButtonLabel,
  });

  ConfirmationDialogState copyWith({
    ConfirmationDialogStatus? status,
    String? title,
    String? message,
    String? confirmButtonLabel,
    String? cancelButtonLabel,
  }) {
    return ConfirmationDialogState(
      status: status ?? this.status,
      title: title ?? this.title,
      message: message ?? this.message,
      confirmButtonLabel: confirmButtonLabel ?? this.confirmButtonLabel,
      cancelButtonLabel: cancelButtonLabel ?? this.cancelButtonLabel,
    );
  }

  @override
  List<Object?> get props => [status, title, message, confirmButtonLabel, cancelButtonLabel];
}
