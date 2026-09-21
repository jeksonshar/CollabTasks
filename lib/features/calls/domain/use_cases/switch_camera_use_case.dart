import 'package:collab_tasks/features/calls/domain/services/rtc_service.dart';

class SwitchCameraUseCase {
  final RtcService _rtcService;

  const SwitchCameraUseCase(this._rtcService);

  Future<void> call() {
    return _rtcService.switchCamera();
  }
}
