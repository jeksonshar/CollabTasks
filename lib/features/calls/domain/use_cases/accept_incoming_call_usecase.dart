import 'package:collab_tasks/features/calls/domain/models/call_data_entity.dart';
import 'package:collab_tasks/features/calls/domain/models/call_participant.dart';
import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
import 'package:collab_tasks/features/calls/domain/models/call_status.dart';
import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';
import 'package:collab_tasks/features/calls/domain/services/call_kit_service.dart';

/// Accepts an incoming call and returns credentials for joining its RTC session.
class AcceptIncomingCallUseCase {
  final CallRepository _callRepository;
  final CallKitService _callKitService;

  const AcceptIncomingCallUseCase({
    required CallRepository callRepository,
    required CallKitService callKitService,
  }) : _callRepository = callRepository,
       _callKitService = callKitService;

  Future<CallSession?> call({required CallDataEntity callData, required String userId}) async {
    final call = await _callRepository.getCallById(callData.callId);
    final normalizedUserId = userId.trim().toLowerCase();
    final isRingingParticipant =
        call?.participants.any(
          (candidate) =>
              candidate.userId.trim().toLowerCase() == normalizedUserId &&
              candidate.status == CallParticipantStatus.ringing,
        ) ??
        false;
    final isAcceptable =
        call != null &&
        (call.status == CallStatus.ringing || call.status == CallStatus.active) &&
        call.calleeIds.any((id) => id.trim().toLowerCase() == normalizedUserId) &&
        isRingingParticipant;

    if (!isAcceptable) {
      await _callKitService.endCall(callData.callId);
      return null;
    }

    await _callKitService.endCall(callData.callId);
    try {
      await _callRepository.acceptCall(callId: callData.callId, userId: userId);
    } catch (_) {
      // The caller can cancel between the read above and the transaction.
      // Treat that race as a stale native action instead of surfacing a
      // permission error for a call which is no longer available.
      final latestCall = await _callRepository.getCallById(callData.callId);
      if (latestCall == null ||
          latestCall.status == CallStatus.ended ||
          latestCall.status == CallStatus.cancelled ||
          latestCall.status == CallStatus.rejected) {
        return null;
      }
      rethrow;
    }
    return _callRepository.getCallSession(callId: callData.callId, userId: userId);
  }
}
