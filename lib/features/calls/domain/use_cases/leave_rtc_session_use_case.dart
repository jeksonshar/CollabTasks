import 'package:collab_tasks/features/calls/domain/services/rtc_service.dart';

class LeaveRtcSessionUseCase {
  final RtcService _rtcService;

  const LeaveRtcSessionUseCase(this._rtcService);

  Future<void> call() {
    return _rtcService.leaveSession();
  }
}
