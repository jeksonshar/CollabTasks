import 'package:collab_tasks/features/calls/domain/models/rtc_participant_media_state.dart';
import 'package:collab_tasks/features/calls/domain/services/rtc_service.dart';

class WatchRtcParticipantMediaStatesUseCase {
  final RtcService _rtcService;

  const WatchRtcParticipantMediaStatesUseCase(this._rtcService);

  Stream<List<RtcParticipantMediaState>> call() {
    return _rtcService.participantMediaStatesStream;
  }
}
