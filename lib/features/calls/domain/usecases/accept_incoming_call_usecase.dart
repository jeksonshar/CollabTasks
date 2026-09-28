import 'package:collab_tasks/features/calls/domain/models/call_data_entity.dart';
import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
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

  Future<CallSession> call({required CallDataEntity callData, required String userId}) async {
    await _callKitService.endCall(callData.callId);
    await _callRepository.acceptCall(callId: callData.callId, userId: userId);
    return _callRepository.getCallSession(callId: callData.callId, userId: userId);
  }
}
