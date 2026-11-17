import 'package:equatable/equatable.dart';

abstract class CallHistoryEvent extends Equatable {
  const CallHistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadCallHistory extends CallHistoryEvent {
  final String currentUserId;
  final String? groupId;
  final String? opponentId;

  const LoadCallHistory({required this.currentUserId, this.groupId, this.opponentId});

  @override
  List<Object?> get props => [currentUserId, groupId, opponentId];
}

class LoadMoreCallHistory extends CallHistoryEvent {
  const LoadMoreCallHistory();
}
