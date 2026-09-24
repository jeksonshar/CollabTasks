import 'package:collab_tasks/features/calls/domain/services/call_alert_service.dart';

class StopCallAlertUseCase {
  final CallAlertService _callAlertService;

  const StopCallAlertUseCase(this._callAlertService);

  Future<void> call() => _callAlertService.stop();
}
