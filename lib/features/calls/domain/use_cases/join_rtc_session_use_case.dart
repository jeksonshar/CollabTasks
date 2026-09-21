import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
import 'package:collab_tasks/features/calls/domain/services/rtc_service.dart';

class JoinRtcSessionUseCase {
  final RtcService _rtcService;

  const JoinRtcSessionUseCase(this._rtcService);

  Future<void> call(CallSession session) {
    return _rtcService.joinSession(session);
  }
}
