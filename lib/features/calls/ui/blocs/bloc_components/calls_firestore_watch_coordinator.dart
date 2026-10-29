import 'dart:async';

import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/watch_active_call_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/watch_incoming_calls_use_case.dart';

/// Owns the Firestore stream subscriptions used by a single CallsBloc.
///
/// CallsBloc supplies the callbacks so it remains responsible for translating
/// snapshots into events and validating active-call watch generations.
class CallsFirestoreWatchCoordinator {
  CallsFirestoreWatchCoordinator({
    required WatchActiveCallUseCase watchActiveCall,
    required WatchIncomingCallsUseCase watchIncomingCalls,
  }) : _watchActiveCall = watchActiveCall,
       _watchIncomingCalls = watchIncomingCalls;

  final WatchActiveCallUseCase _watchActiveCall;
  final WatchIncomingCallsUseCase _watchIncomingCalls;

  StreamSubscription<Call?>? _activeCallSubscription;
  StreamSubscription<List<Call>>? _incomingCallsSubscription;

  /// Cancels the current listener when another listen request is beginning.
  /// The subscription slot is left intact until the replacement is installed,
  /// matching the Bloc's previous restart ordering.
  void cancelIncomingCallsForRestart() {
    _incomingCallsSubscription?.cancel();
  }

  /// Stops incoming updates without waiting, matching StopListening behavior.
  void stopIncomingCalls() {
    _incomingCallsSubscription?.cancel();
    _incomingCallsSubscription = null;
  }

  /// Cancels on Bloc close and clears the slot after cancellation completes.
  Future<void> closeIncomingCalls() async {
    await _incomingCallsSubscription?.cancel();
    _incomingCallsSubscription = null;
  }

  void listenIncomingCalls(
    String userId, {
    required void Function(List<Call> calls) onData,
    required void Function(Object error) onError,
  }) {
    _incomingCallsSubscription = _watchIncomingCalls(userId).listen(onData, onError: onError);
  }

  Future<void> watchActiveCall(
    String callId, {
    required bool Function() canListen,
    required void Function(Call? call) onData,
    required void Function(Object error) onError,
  }) async {
    // Capture the subscription before awaiting cancellation. Concurrent watch
    // requests must not cancel a newer subscription installed while this await
    // is pending; CallsBloc's generation check decides which request may start.
    final previousSubscription = _activeCallSubscription;
    await previousSubscription?.cancel();
    if (!canListen()) return;

    _activeCallSubscription = _watchActiveCall(callId).listen(onData, onError: onError);
  }

  Future<void> cancelActiveCall() async {
    await _activeCallSubscription?.cancel();
    _activeCallSubscription = null;
  }
}
