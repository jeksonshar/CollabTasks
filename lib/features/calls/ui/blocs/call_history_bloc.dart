import 'package:collab_tasks/features/calls/domain/use_cases/get_call_history_use_case.dart';
import 'package:collab_tasks/features/calls/ui/blocs/call_history_event.dart';
import 'package:collab_tasks/features/calls/ui/blocs/call_history_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show Bloc, Emitter;

class CallHistoryBloc extends Bloc<CallHistoryEvent, CallHistoryState> {
  static const int pageSize = 20;

  final GetCallHistoryUseCase _getCallHistory;
  int _requestGeneration = 0;

  CallHistoryBloc(this._getCallHistory) : super(const CallHistoryInitial()) {
    on<LoadCallHistory>(_onLoad);
    on<LoadMoreCallHistory>(_onLoadMore);
  }

  Future<void> _onLoad(LoadCallHistory event, Emitter<CallHistoryState> emit) async {
    final generation = ++_requestGeneration;
    emit(const CallHistoryLoading());
    try {
      final page = await _getCallHistory(
        currentUserId: event.currentUserId,
        pageSize: pageSize,
        groupId: event.groupId,
        opponentId: event.opponentId,
      );
      if (generation != _requestGeneration) return;
      emit(
        CallHistoryLoaded(
          calls: page.calls,
          currentUserId: event.currentUserId,
          groupId: event.groupId,
          opponentId: event.opponentId,
          pageSize: pageSize,
          nextCursor: page.nextCursor,
        ),
      );
    } catch (error) {
      debugPrint('[call_history_bloc] _onLoadError - $error');
      if (generation == _requestGeneration) emit(CallHistoryError(error));
    }
  }

  Future<void> _onLoadMore(LoadMoreCallHistory event, Emitter<CallHistoryState> emit) async {
    final loaded = state;
    if (loaded is! CallHistoryLoaded || !loaded.hasMore || loaded.isLoadingMore) return;

    final generation = _requestGeneration;
    emit(loaded.copyWith(isLoadingMore: true, clearPageError: true));
    try {
      final page = await _getCallHistory(
        currentUserId: loaded.currentUserId,
        pageSize: loaded.pageSize,
        groupId: loaded.groupId,
        opponentId: loaded.opponentId,
        cursor: loaded.nextCursor,
      );
      if (generation != _requestGeneration || state is! CallHistoryLoaded) return;
      final latestState = state as CallHistoryLoaded;
      if (latestState.currentUserId != loaded.currentUserId ||
          latestState.groupId != loaded.groupId ||
          latestState.opponentId != loaded.opponentId ||
          latestState.nextCursor?.createdAtMillis != loaded.nextCursor?.createdAtMillis ||
          latestState.nextCursor?.callId != loaded.nextCursor?.callId) {
        return;
      }

      final seenIds = loaded.calls.map((call) => call.id).toSet();
      final appendedCalls = [...loaded.calls, ...page.calls.where((call) => seenIds.add(call.id))];
      emit(
        loaded.copyWith(
          calls: appendedCalls,
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          isLoadingMore: false,
          clearPageError: true,
        ),
      );
    } catch (error) {
      debugPrint('[call_history_bloc] _onLoadMoreError - $error');
      if (generation == _requestGeneration && state is CallHistoryLoaded) {
        emit((state as CallHistoryLoaded).copyWith(isLoadingMore: false, pageError: error));
      }
    }
  }
}
