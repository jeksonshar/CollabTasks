import 'package:collab_tasks/features/calls/domain/services/call_alert_service.dart';
import 'package:collab_tasks/features/calls/domain/services/call_kit_service.dart';

class CancelIncomingCallUseCase {
  final CallKitService _callKitService;
  final CallAlertService _callAlertService;

  const CancelIncomingCallUseCase({
    required CallKitService callKitService,
    required CallAlertService callAlertService,
  }) : _callKitService = callKitService,
       _callAlertService = callAlertService;

  Future<void> call(String callId) async {
    await _callKitService.endCall(callId);
    await _callAlertService.stop();
  }
}
