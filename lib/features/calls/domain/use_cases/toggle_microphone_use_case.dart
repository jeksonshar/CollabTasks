import 'package:collab_tasks/features/calls/domain/services/rtc_service.dart';

class ToggleMicrophoneUseCase {
  final RtcService _rtcService;

  const ToggleMicrophoneUseCase(this._rtcService);

  Future<void> call(bool isMuted) {
    return _rtcService.setMicrophoneMuted(isMuted);
  }
}
