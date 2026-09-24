import 'package:collab_tasks/features/calls/domain/services/call_alert_service.dart';

class StartIncomingAlertUseCase {
  final CallAlertService _callAlertService;

  const StartIncomingAlertUseCase(this._callAlertService);

  Future<void> call() => _callAlertService.startIncomingRingtone();
}
