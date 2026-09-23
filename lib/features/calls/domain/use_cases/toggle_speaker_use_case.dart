import 'package:collab_tasks/features/calls/domain/services/rtc_service.dart';

class ToggleSpeakerUseCase {
  final RtcService _rtcService;

  const ToggleSpeakerUseCase(this._rtcService);

  Future<void> call(bool isSpeaker) {
    return _rtcService.setSpeakerEnabled(isSpeaker);
  }
}
