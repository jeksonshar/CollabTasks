import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';
import 'package:collab_tasks/features/calls/domain/services/call_alert_service.dart';
import 'package:collab_tasks/features/calls/domain/services/call_kit_service.dart';

class DeclineIncomingCallUseCase {
  final CallRepository _callRepository;
  final CallAlertService _callAlertService;
  final CallKitService _callKitService;

  const DeclineIncomingCallUseCase({
    required this._callRepository,
    required this._callAlertService,
    required this._callKitService,
  });

  Future<void> call({required String callId, required String userId}) async {
    try {
      await _callRepository.rejectCall(callId: callId, userId: userId);
    } finally {
      try {
        await _callAlertService.stop();
      } finally {
        await _callKitService.endCall(callId);
      }
    }
  }
}
