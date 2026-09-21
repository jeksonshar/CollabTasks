import 'package:collab_tasks/features/calls/domain/models/rtc_connection_state.dart';
import 'package:collab_tasks/features/calls/domain/services/rtc_service.dart';

class WatchRtcConnectionStateUseCase {
  final RtcService _rtcService;

  const WatchRtcConnectionStateUseCase(this._rtcService);

  Stream<RtcConnectionState> call() {
    return _rtcService.connectionStateStream;
  }
}
