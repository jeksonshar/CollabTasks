import 'package:collab_tasks/features/calls/domain/use_cases/get_call_history_use_case.dart';
import 'package:collab_tasks/features/calls/ui/blocs/call_history_event.dart';
import 'package:collab_tasks/features/calls/ui/blocs/call_history_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show Bloc, Emitter;

class CallHistoryBloc extends Bloc<CallHistoryEvent, CallHistoryState> {
  final GetCallHistoryUseCase _getCallHistory;

  CallHistoryBloc(this._getCallHistory) : super(const CallHistoryInitial()) {
    on<LoadCallHistory>(_onLoad);
  }

  Future<void> _onLoad(LoadCallHistory event, Emitter<CallHistoryState> emit) async {
    emit(const CallHistoryLoading());
    try {
      final calls = await _getCallHistory(
        currentUserId: event.currentUserId,
        groupId: event.groupId,
        opponentId: event.opponentId,
      );
      emit(CallHistoryLoaded(calls));
    } catch (error) {
      debugPrint('[call_history_bloc] _onLoadError - $error');
      emit(CallHistoryError(error));
    }
  }
}
