import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_connection_state.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_participant_media_state.dart';

abstract class RtcService {
  /// Connects/joins an active RTC media session.
  Future<void> joinSession(CallSession session);

  /// Leaves/disconnects from the active RTC media session.
  Future<void> leaveSession();

  /// Mutes or unmutes the local microphone.
  Future<void> setMicrophoneMuted(bool muted);

  /// Set speaker or Earpiece phone.
  Future<void> setSpeakerEnabled(bool enabled);

  /// Enables or disables the local camera stream.
  Future<void> setCameraEnabled(bool enabled);

  /// Switches between available video cameras (e.g. front and rear).
  Future<void> switchCamera();

  /// Current connection state of the RTC transport.
  RtcConnectionState get currentConnectionState;

  /// Stream of connection state updates (connecting, connected, reconnecting, etc.).
  Stream<RtcConnectionState> get connectionStateStream;

  /// Current media states of local and remote participants.
  List<RtcParticipantMediaState> get currentParticipantMediaStates;

  /// Stream of participant media states (mute, video enable, speaking, audio level).
  Stream<List<RtcParticipantMediaState>> get participantMediaStatesStream;

  /// Releases internal resources and closes streams.
  Future<void> dispose();
}
