import 'dart:async';

import 'package:collab_tasks/features/calls/domain/use_cases/update_call_heartbeat_use_case.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_event.dart';
import 'package:flutter/foundation.dart';

/// Owns heartbeat and reconciliation timers; CallsBloc remains the source of
/// call state and decides whether a reconciliation result is still relevant.
class CallLivenessCoordinator {
  CallLivenessCoordinator({
    required UpdateCallHeartbeatUseCase? updateHeartbeat,
    required void Function(CallsEvent event) dispatch,
  }) : _updateHeartbeat = updateHeartbeat,
       _dispatch = dispatch;

  final UpdateCallHeartbeatUseCase? _updateHeartbeat;
  final void Function(CallsEvent event) _dispatch;
  Timer? _heartbeatTimer;
  Timer? _reconciliationTimer;
  String? _heartbeatCallId;
  String? _reconciliationCallId;
  bool _heartbeatWriteInProgress = false;

  static const Duration heartbeatInterval = Duration(seconds: 15);
  static const Duration reconciliationInterval = Duration(seconds: 10);

  void startHeartbeat({
    required String callId,
    required String userId,
    required bool Function() isCurrent,
  }) {
    if (_updateHeartbeat == null) return;
    if (_heartbeatCallId == callId && _heartbeatTimer != null) return;

    stopHeartbeat();
    _heartbeatCallId = callId;
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      if (!isCurrent()) {
        stopHeartbeat();
        return;
      }
      unawaited(_sendHeartbeat(callId, userId));
    });
  }

  void startReconciliation({required String callId, required bool Function() isCurrent}) {
    if (_reconciliationCallId == callId && _reconciliationTimer != null) return;
    stopReconciliation();
    _reconciliationCallId = callId;
    _dispatch(CallLivenessCheckRequested(callId));
    _reconciliationTimer = Timer.periodic(reconciliationInterval, (_) {
      if (!isCurrent()) {
        stopReconciliation();
        return;
      }
      _dispatch(CallLivenessCheckRequested(callId));
    });
  }

  void stopReconciliation() {
    _reconciliationTimer?.cancel();
    _reconciliationTimer = null;
    _reconciliationCallId = null;
  }

  Future<void> _sendHeartbeat(String callId, String userId) async {
    if (_heartbeatWriteInProgress) return;
    _heartbeatWriteInProgress = true;
    try {
      await _updateHeartbeat?.call(callId: callId, userId: userId);
    } catch (error) {
      debugPrint('[CallLiveness] Heartbeat failed for $callId: $error');
    } finally {
      _heartbeatWriteInProgress = false;
    }
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _heartbeatCallId = null;
  }

  void stop() {
    stopHeartbeat();
    stopReconciliation();
  }
}
