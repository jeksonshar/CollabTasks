import 'package:flutter_bloc/flutter_bloc.dart';

import 'confirmation_dialog_event.dart';
import 'confirmation_dialog_state.dart';

class ConfirmationDialogBloc extends Bloc<ConfirmationDialogEvent, ConfirmationDialogState> {
  ConfirmationDialogBloc() : super(const ConfirmationDialogState()) {
    on<InitializeConfirmationDialog>(_onInitialize);
    on<ConfirmationDialogConfirmed>(_onConfirmed);
    on<ConfirmationDialogCancelled>(_onCancelled);
    on<ResetConfirmationDialog>(_onReset);
  }

  Future<void> _onInitialize(
    InitializeConfirmationDialog event,
    Emitter<ConfirmationDialogState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ConfirmationDialogStatus.pending,
        title: event.title,
        message: event.message,
        confirmButtonLabel: event.confirmButtonLabel,
        cancelButtonLabel: event.cancelButtonLabel,
      ),
    );
  }

  Future<void> _onConfirmed(
    ConfirmationDialogConfirmed event,
    Emitter<ConfirmationDialogState> emit,
  ) async {
    emit(state.copyWith(status: ConfirmationDialogStatus.confirmed));
  }

  Future<void> _onCancelled(
    ConfirmationDialogCancelled event,
    Emitter<ConfirmationDialogState> emit,
  ) async {
    emit(state.copyWith(status: ConfirmationDialogStatus.cancelled));
  }

  Future<void> _onReset(
    ResetConfirmationDialog event,
    Emitter<ConfirmationDialogState> emit,
  ) async {
    emit(const ConfirmationDialogState());
  }
}
