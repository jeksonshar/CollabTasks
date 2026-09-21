import 'dart:async';

import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/models/call_participant.dart';
import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
import 'package:collab_tasks/features/calls/domain/models/call_status.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

class InMemoryCallRepository implements CallRepository {
  final Map<String, Call> _calls = {};
  final Map<String, StreamController<Call?>> _activeCallControllers = {};
  final Map<String, StreamController<List<Call>>> _incomingCallsControllers = {};

  final _uuid = const Uuid();

  @override
  Stream<Call?> watchActiveCall(String callId) {
    return _activeCallControllers
        .putIfAbsent(callId, () => StreamController<Call?>.broadcast())
        .stream;
  }

  @override
  Stream<List<Call>> watchIncomingCalls(String userId) {
    return _incomingCallsControllers
        .putIfAbsent(userId, () => StreamController<List<Call>>.broadcast())
        .stream;
  }

  @override
  Future<Call> startCall({
    required String callerId,
    required String callerName,
    String? callerAvatarUrl,
    required List<String> calleeIds,
    required CallType type,
    bool isGroup = false,
    String? groupId,
  }) async {
    final now = DateTime.now();
    final callId = _uuid.v4();

    final participants = [
      CallParticipant(
        userId: callerId,
        displayName: callerName,
        avatarUrl: callerAvatarUrl,
        role: CallParticipantRole.host,
        status: CallParticipantStatus.connected,
        joinedAt: now,
      ),
      ...calleeIds.map(
        (id) => CallParticipant(
          userId: id,
          displayName: 'User $id',
          role: CallParticipantRole.participant,
          status: CallParticipantStatus.ringing,
        ),
      ),
    ];

    final call = Call(
      id: callId,
      callerId: callerId,
      callerName: callerName,
      callerAvatarUrl: callerAvatarUrl,
      calleeIds: calleeIds,
      type: type,
      status: CallStatus.ringing,
      isGroup: isGroup,
      groupId: groupId,
      participants: participants,
      createdAt: now,
    );

    _calls[callId] = call;
    _notifyActiveCall(callId, call);

    for (final calleeId in calleeIds) {
      _notifyIncomingCalls(calleeId);
    }

    return call;
  }

  @override
  Future<void> acceptCall({required String callId, required String userId}) async {
    final call = _calls[callId];
    if (call == null) return;

    final updatedParticipants = call.participants.map((p) {
      if (p.userId == userId) {
        return p.copyWith(status: CallParticipantStatus.connected, joinedAt: DateTime.now());
      }
      return p;
    }).toList();

    final updatedCall = call.copyWith(
      status: CallStatus.active,
      startedAt: call.startedAt ?? DateTime.now(),
      participants: updatedParticipants,
    );

    _calls[callId] = updatedCall;
    _notifyActiveCall(callId, updatedCall);

    for (final calleeId in call.calleeIds) {
      _notifyIncomingCalls(calleeId);
    }
  }

  @override
  Future<void> rejectCall({required String callId, required String userId}) async {
    final call = _calls[callId];
    if (call == null) return;

    final updatedParticipants = call.participants.map((p) {
      if (p.userId == userId) {
        return p.copyWith(status: CallParticipantStatus.declined);
      }
      return p;
    }).toList();

    final allDeclined = updatedParticipants
        .where((p) => p.role != CallParticipantRole.host)
        .every((p) => p.status == CallParticipantStatus.declined);

    final updatedCall = call.copyWith(
      status: allDeclined ? CallStatus.rejected : call.status,
      participants: updatedParticipants,
      endedAt: allDeclined ? DateTime.now() : null,
    );

    _calls[callId] = updatedCall;
    _notifyActiveCall(callId, updatedCall);

    for (final calleeId in call.calleeIds) {
      _notifyIncomingCalls(calleeId);
    }
  }

  @override
  Future<void> endCall(String callId) async {
    final call = _calls[callId];
    debugPrint('endCall() pressed, call = $call');
    if (call == null) return;

    final updatedCall = call.copyWith(status: CallStatus.ended, endedAt: DateTime.now());

    _calls[callId] = updatedCall;
    _notifyActiveCall(callId, updatedCall);

    for (final calleeId in call.calleeIds) {
      _notifyIncomingCalls(calleeId);
    }
  }

  @override
  Future<void> cancelCall(String callId) async {
    final call = _calls[callId];
    if (call == null) return;

    final updatedCall = call.copyWith(status: CallStatus.cancelled, endedAt: DateTime.now());

    _calls[callId] = updatedCall;
    _notifyActiveCall(callId, updatedCall);

    for (final calleeId in call.calleeIds) {
      _notifyIncomingCalls(calleeId);
    }
  }

  @override
  Future<void> leaveCall({required String callId, required String userId}) async {
    final call = _calls[callId];
    if (call == null) return;

    final updatedParticipants = call.participants.map<CallParticipant>((p) {
      if (p.userId == userId) {
        return p.copyWith(status: CallParticipantStatus.left);
      }
      return p;
    }).toList();

    final remainingConnected = updatedParticipants.where(
      (p) => p.status == CallParticipantStatus.connected,
    );

    final shouldEnd =
        remainingConnected.isEmpty || (!call.isGroup && remainingConnected.length < 2);

    final updatedCall = call.copyWith(
      status: shouldEnd ? CallStatus.ended : call.status,
      endedAt: shouldEnd ? DateTime.now() : null,
      participants: updatedParticipants,
    );

    _calls[callId] = updatedCall;
    _notifyActiveCall(callId, updatedCall);

    for (final calleeId in call.calleeIds) {
      _notifyIncomingCalls(calleeId);
    }
  }

  @override
  Future<void> inviteParticipant({
    required String callId,
    required String userId,
    required String displayName,
    String? avatarUrl,
  }) async {
    final call = _calls[callId];
    if (call == null) return;

    if (call.participants.any((p) => p.userId == userId)) return;

    final newParticipant = CallParticipant(
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      role: CallParticipantRole.participant,
      status: CallParticipantStatus.ringing,
    );

    final updatedCalleeIds = List<String>.from(call.calleeIds);
    if (!updatedCalleeIds.contains(userId)) {
      updatedCalleeIds.add(userId);
    }

    final updatedCall = call.copyWith(
      calleeIds: updatedCalleeIds,
      participants: [...call.participants, newParticipant],
    );

    _calls[callId] = updatedCall;
    _notifyActiveCall(callId, updatedCall);
    _notifyIncomingCalls(userId);
  }

  @override
  Future<CallSession> getCallSession({required String callId, required String userId}) async {
    final call = _calls[callId];
    debugPrint('getCallSession(), call = $call');
    if (call == null) {
      throw StateError('Call with id $callId not found');
    }
    return CallSession(
      callId: callId,
      roomId: 'room_$callId',
      token: 'fake_token_${callId}_$userId',
      localUserId: userId,
      extra: {'provider': 'fake', 'mediaType': call.type.name},
    );
  }

  @override
  Future<Call?> getCallById(String callId) async {
    return _calls[callId];
  }

  void _notifyActiveCall(String callId, Call? call) {
    if (_activeCallControllers.containsKey(callId) && !_activeCallControllers[callId]!.isClosed) {
      _activeCallControllers[callId]!.add(call);
    }
  }

  void _notifyIncomingCalls(String userId) {
    if (_incomingCallsControllers.containsKey(userId) &&
        !_incomingCallsControllers[userId]!.isClosed) {
      final incoming = _calls.values
          .where(
            (c) =>
                c.calleeIds.contains(userId) &&
                c.status == CallStatus.ringing &&
                c.participants.any(
                  (p) => p.userId == userId && p.status == CallParticipantStatus.ringing,
                ),
          )
          .toList();
      _incomingCallsControllers[userId]!.add(incoming);
    }
  }

  void dispose() {
    for (final controller in _activeCallControllers.values) {
      controller.close();
    }
    for (final controller in _incomingCallsControllers.values) {
      controller.close();
    }
    _activeCallControllers.clear();
    _incomingCallsControllers.clear();
  }
}
