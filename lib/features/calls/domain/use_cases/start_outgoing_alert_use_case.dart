import 'package:collab_tasks/features/calls/domain/services/call_alert_service.dart';

class StartOutgoingAlertUseCase {
  final CallAlertService _callAlertService;

  const StartOutgoingAlertUseCase(this._callAlertService);

  Future<void> call() => _callAlertService.startOutgoingRingtone();
}
