import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';
import 'package:equatable/equatable.dart';

abstract class CallHistoryState extends Equatable {
  const CallHistoryState();

  @override
  List<Object?> get props => [];
}

class CallHistoryInitial extends CallHistoryState {
  const CallHistoryInitial();
}

class CallHistoryLoading extends CallHistoryState {
  const CallHistoryLoading();
}

class CallHistoryLoaded extends CallHistoryState {
  final List<Call> calls;
  final String currentUserId;
  final String? groupId;
  final String? opponentId;
  final int pageSize;
  final CallHistoryCursor? nextCursor;
  final bool isLoadingMore;
  final Object? pageError;

  const CallHistoryLoaded({
    required this.calls,
    required this.currentUserId,
    this.groupId,
    this.opponentId,
    required this.pageSize,
    this.nextCursor,
    this.isLoadingMore = false,
    this.pageError,
  });

  bool get hasMore => nextCursor != null;

  CallHistoryLoaded copyWith({
    List<Call>? calls,
    CallHistoryCursor? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMore,
    Object? pageError,
    bool clearPageError = false,
  }) => CallHistoryLoaded(
    calls: calls ?? this.calls,
    currentUserId: currentUserId,
    groupId: groupId,
    opponentId: opponentId,
    pageSize: pageSize,
    nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    pageError: clearPageError ? null : pageError ?? this.pageError,
  );

  @override
  List<Object?> get props => [
    calls,
    currentUserId,
    groupId,
    opponentId,
    pageSize,
    nextCursor?.createdAtMillis,
    nextCursor?.callId,
    isLoadingMore,
    pageError,
  ];
}

class CallHistoryError extends CallHistoryState {
  final Object error;

  const CallHistoryError(this.error);

  @override
  List<Object?> get props => [error];
}
