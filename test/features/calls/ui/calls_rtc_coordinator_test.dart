import 'package:collab_tasks/features/calls/data/rtc/fake_rtc_service.dart';
import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/join_rtc_session_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/leave_rtc_session_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/switch_camera_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/toggle_camera_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/toggle_microphone_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/toggle_speaker_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/watch_rtc_connection_state_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/watch_rtc_participant_media_states_use_case.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_event.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_rtc_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeRtcService rtcService;
  late List<CallsEvent> dispatchedEvents;
  late CallsRtcCoordinator coordinator;

  setUp(() {
    rtcService = FakeRtcService();
    dispatchedEvents = [];
    coordinator = CallsRtcCoordinator(
      joinRtcSession: JoinRtcSessionUseCase(rtcService),
      leaveRtcSession: LeaveRtcSessionUseCase(rtcService),
      toggleMicrophone: ToggleMicrophoneUseCase(rtcService),
      toggleCamera: ToggleCameraUseCase(rtcService),
      toggleSpeaker: ToggleSpeakerUseCase(rtcService),
      switchCamera: SwitchCameraUseCase(rtcService),
      watchConnectionState: WatchRtcConnectionStateUseCase(rtcService),
      watchParticipantMediaStates: WatchRtcParticipantMediaStatesUseCase(rtcService),
      dispatch: dispatchedEvents.add,
    );
  });

  tearDown(() async {
    await coordinator.cancelSubscriptions();
    await rtcService.dispose();
  });

  test('deduplicates joins and forwards RTC streams as Bloc events', () async {
    const session = CallSession(
      callId: 'call-rtc-coordinator',
      roomId: 'room-rtc-coordinator',
      token: 'token',
      localUserId: 'local-user',
    );

    await coordinator.joinSession(session, isTerminal: false);
    await coordinator.joinSession(session, isTerminal: false);

    expect(rtcService.joinCallCount, 1);
    expect(dispatchedEvents.whereType<RtcConnectionStateChanged>(), isNotEmpty);
    expect(dispatchedEvents.whereType<ParticipantMediaStatesUpdated>(), isNotEmpty);
  });

  test(
    'does not join a terminal call and allows another call after forgetting prior call',
    () async {
      const terminalSession = CallSession(
        callId: 'terminal-call',
        roomId: 'terminal-room',
        token: 'token',
        localUserId: 'local-user',
      );
      const nextSession = CallSession(
        callId: 'next-call',
        roomId: 'next-room',
        token: 'token',
        localUserId: 'local-user',
      );

      await coordinator.joinSession(terminalSession, isTerminal: true);
      expect(rtcService.joinCallCount, 0);

      await coordinator.joinSession(terminalSession, isTerminal: false);
      await coordinator.leaveSession();
      coordinator.forgetCall(terminalSession.callId);
      await coordinator.joinSession(nextSession, isTerminal: false);

      expect(rtcService.joinCallCount, 2);
      expect(rtcService.lastJoinedSession, nextSession);
    },
  );

  test('delegates media commands without changing their order', () async {
    await coordinator.toggleMicrophone(true);
    await coordinator.toggleCamera(false);
    await coordinator.toggleSpeaker(true);
    await coordinator.switchCamera();

    expect(rtcService.isMicrophoneMuted, isTrue);
    expect(rtcService.isCameraEnabled, isFalse);
    expect(rtcService.isSpeakerEnabled, isTrue);
    expect(rtcService.switchCameraCallCount, 1);
  });
}
