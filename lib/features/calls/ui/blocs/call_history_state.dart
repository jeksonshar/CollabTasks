import 'package:collab_tasks/features/calls/domain/models/call.dart';
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

  const CallHistoryLoaded(this.calls);

  @override
  List<Object?> get props => [calls];
}

class CallHistoryError extends CallHistoryState {
  final Object error;

  const CallHistoryError(this.error);

  @override
  List<Object?> get props => [error];
}
