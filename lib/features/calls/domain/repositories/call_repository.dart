import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';

abstract class CallRepository {
  /// Watches updates to a specific call by its ID.
  Stream<Call?> watchActiveCall(String callId);

  /// Watches incoming calls for the specified user.
  Stream<List<Call>> watchIncomingCalls(String userId);

  /// Initiates a new 1-to-1 or group call.
  Future<Call> startCall({
    required String callerId,
    required String callerName,
    String? callerAvatarUrl,
    required List<String> calleeIds,
    required CallType type,
    bool isGroup = false,
    String? groupId,
  });

  /// Accepts an incoming call for the specified user.
  Future<void> acceptCall({required String callId, required String userId});

  /// Rejects an incoming call for the specified user.
  Future<void> rejectCall({required String callId, required String userId});

  /// Ends an active or pending call.
  Future<void> endCall(String callId);

  /// Cancels an outgoing pending/ringing call before it is answered.
  Future<void> cancelCall(String callId);

  /// Leaves an active call for a specific participant without terminating the call for others.
  Future<void> leaveCall({required String callId, required String userId});

  /// Invites a new participant to an ongoing group call.
  Future<void> inviteParticipant({
    required String callId,
    required String userId,
    required String displayName,
    String? avatarUrl,
  });

  /// Obtains the RTC session credentials for joining the call.
  Future<CallSession> getCallSession({required String callId, required String userId});

  /// Fetches a call by its unique identifier.
  Future<Call?> getCallById(String callId);
}
