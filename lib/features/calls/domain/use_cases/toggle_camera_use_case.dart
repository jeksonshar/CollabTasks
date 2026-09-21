import 'package:collab_tasks/features/calls/domain/services/rtc_service.dart';

class ToggleCameraUseCase {
  final RtcService _rtcService;

  const ToggleCameraUseCase(this._rtcService);

  Future<void> call(bool isEnabled) {
    return _rtcService.setCameraEnabled(isEnabled);
  }
}
