import 'dart:async';

import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_connection_state.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_participant_media_state.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/join_rtc_session_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/leave_rtc_session_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/switch_camera_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/toggle_camera_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/toggle_microphone_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/toggle_speaker_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/watch_rtc_connection_state_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/watch_rtc_participant_media_states_use_case.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_event.dart';

/// Owns RTC commands, duplicate-join protection, and RTC stream subscriptions.
/// CallsBloc remains responsible for state transitions and terminal policy.
class CallsRtcCoordinator {
  CallsRtcCoordinator({
    required JoinRtcSessionUseCase joinRtcSession,
    required LeaveRtcSessionUseCase leaveRtcSession,
    required ToggleMicrophoneUseCase toggleMicrophone,
    required ToggleCameraUseCase toggleCamera,
    required ToggleSpeakerUseCase toggleSpeaker,
    required SwitchCameraUseCase switchCamera,
    required WatchRtcConnectionStateUseCase watchConnectionState,
    required WatchRtcParticipantMediaStatesUseCase watchParticipantMediaStates,
    required void Function(CallsEvent event) dispatch,
  }) : _joinRtcSession = joinRtcSession,
       _leaveRtcSession = leaveRtcSession,
       _toggleMicrophone = toggleMicrophone,
       _toggleCamera = toggleCamera,
       _toggleSpeaker = toggleSpeaker,
       _switchCamera = switchCamera,
       _watchConnectionState = watchConnectionState,
       _watchParticipantMediaStates = watchParticipantMediaStates,
       _dispatch = dispatch;

  final JoinRtcSessionUseCase _joinRtcSession;
  final LeaveRtcSessionUseCase _leaveRtcSession;
  final ToggleMicrophoneUseCase _toggleMicrophone;
  final ToggleCameraUseCase _toggleCamera;
  final ToggleSpeakerUseCase _toggleSpeaker;
  final SwitchCameraUseCase _switchCamera;
  final WatchRtcConnectionStateUseCase _watchConnectionState;
  final WatchRtcParticipantMediaStatesUseCase _watchParticipantMediaStates;
  final void Function(CallsEvent event) _dispatch;

  final Set<String> _joiningOrJoinedCallIds = {};
  StreamSubscription<RtcConnectionState>? _connectionStateSubscription;
  StreamSubscription<List<RtcParticipantMediaState>>? _participantMediaStatesSubscription;

  Future<void> joinSession(CallSession session, {required bool isTerminal}) async {
    if (isTerminal) return;
    if (!_joiningOrJoinedCallIds.add(session.callId)) return;

    try {
      await _subscribeToStreams();
      await _joinRtcSession(session);
    } catch (_) {
      _joiningOrJoinedCallIds.remove(session.callId);
      rethrow;
    }
  }

  Future<void> toggleMicrophone(bool muted) => _toggleMicrophone(muted);

  Future<void> toggleCamera(bool enabled) => _toggleCamera(enabled);

  Future<void> toggleSpeaker(bool enabled) => _toggleSpeaker(enabled);

  Future<void> switchCamera() => _switchCamera();

  void forgetCall(String callId) {
    _joiningOrJoinedCallIds.remove(callId);
  }

  Future<void> cancelSubscriptions() async {
    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    await _participantMediaStatesSubscription?.cancel();
    _participantMediaStatesSubscription = null;
  }

  Future<void> leaveSession() => _leaveRtcSession();

  Future<void> _subscribeToStreams() async {
    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = _watchConnectionState().listen(
      (rtcState) => _dispatch(RtcConnectionStateChanged(rtcState)),
    );

    await _participantMediaStatesSubscription?.cancel();
    _participantMediaStatesSubscription = _watchParticipantMediaStates().listen(
      (mediaStates) => _dispatch(ParticipantMediaStatesUpdated(mediaStates)),
    );
  }
}
