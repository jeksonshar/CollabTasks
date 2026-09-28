import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';
import 'package:collab_tasks/features/calls/domain/services/call_alert_service.dart';
import 'package:collab_tasks/features/calls/domain/services/call_kit_service.dart';

class DeclineIncomingCallUseCase {
  final CallRepository _callRepository;
  final CallAlertService _callAlertService;
  final CallKitService _callKitService;

  const DeclineIncomingCallUseCase({
    required CallRepository callRepository,
    required CallAlertService callAlertService,
    required CallKitService callKitService,
  }) : _callRepository = callRepository,
       _callAlertService = callAlertService,
       _callKitService = callKitService;

  Future<void> call({required String callId, required String userId}) async {
    await _callRepository.rejectCall(callId: callId, userId: userId);
    await _callAlertService.stop();
    await _callKitService.endCall(callId);
  }
}
