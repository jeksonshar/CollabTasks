import 'package:collab_tasks/features/calls/data/rtc/fake_rtc_service.dart';
import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_connection_state.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_participant_media_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeRtcService fakeRtcService;

  setUp(() {
    fakeRtcService = FakeRtcService();
  });

  tearDown(() async {
    await fakeRtcService.dispose();
  });

  group('FakeRtcService tests', () {
    const testSession = CallSession(
      callId: 'call-123',
      roomId: 'room-123',
      token: 'fake-token',
      localUserId: 'user-me',
    );

    test('join adds local participant and transitions to connected', () async {
      final states = <RtcConnectionState>[];
      final subscription = fakeRtcService.connectionStateStream.listen(states.add);

      expect(fakeRtcService.currentConnectionState, RtcConnectionState.disconnected);
      expect(fakeRtcService.isJoined, isFalse);

      await fakeRtcService.joinSession(testSession);

      expect(fakeRtcService.isJoined, isTrue);
      expect(fakeRtcService.currentConnectionState, RtcConnectionState.connected);
      expect(fakeRtcService.currentParticipantMediaStates.length, 1);
      expect(fakeRtcService.currentParticipantMediaStates.first.participantId, 'user-me');
      expect(fakeRtcService.currentParticipantMediaStates.first.isLocal, isTrue);

      await subscription.cancel();
    });

    test('leave clears session, participants and sets disconnected state', () async {
      await fakeRtcService.joinSession(testSession);
      expect(fakeRtcService.isJoined, isTrue);

      await fakeRtcService.leaveSession();

      expect(fakeRtcService.isJoined, isFalse);
      expect(fakeRtcService.currentConnectionState, RtcConnectionState.disconnected);
      expect(fakeRtcService.currentParticipantMediaStates, isEmpty);
    });

    test('simulateConnectionState emits connected, reconnecting and disconnected', () async {
      final emittedStates = <RtcConnectionState>[];
      final subscription = fakeRtcService.connectionStateStream.listen(emittedStates.add);

      fakeRtcService
        ..simulateConnectionState(RtcConnectionState.connecting)
        ..simulateConnectionState(RtcConnectionState.connected)
        ..simulateConnectionState(RtcConnectionState.reconnecting)
        ..simulateConnectionState(RtcConnectionState.disconnected);

      await pumpEventQueue();

      expect(emittedStates, [
        RtcConnectionState.connecting,
        RtcConnectionState.connected,
        RtcConnectionState.reconnecting,
        RtcConnectionState.disconnected,
      ]);

      await subscription.cancel();
    });

    test('participant joined and participant left simulation', () async {
      await fakeRtcService.joinSession(testSession);

      const remoteUser = RtcParticipantMediaState(
        participantId: 'user-remote',
        isLocal: false,
        isAudioMuted: false,
        isVideoEnabled: true,
      );

      final mediaEvents = <List<RtcParticipantMediaState>>[];
      final sub = fakeRtcService.participantMediaStatesStream.listen(mediaEvents.add);

      fakeRtcService.simulateParticipantJoined(remoteUser);
      await pumpEventQueue();

      expect(fakeRtcService.currentParticipantMediaStates.length, 2);
      expect(
        fakeRtcService.currentParticipantMediaStates.any((p) => p.participantId == 'user-remote'),
        isTrue,
      );

      fakeRtcService.simulateParticipantLeft('user-remote');
      await pumpEventQueue();

      expect(fakeRtcService.currentParticipantMediaStates.length, 1);
      expect(
        fakeRtcService.currentParticipantMediaStates.any((p) => p.participantId == 'user-remote'),
        isFalse,
      );

      await sub.cancel();
    });

    test('microphone mute/unmute updates local participant', () async {
      await fakeRtcService.joinSession(testSession);

      expect(fakeRtcService.isMicrophoneMuted, isFalse);
      expect(fakeRtcService.currentParticipantMediaStates.first.isAudioMuted, isFalse);

      await fakeRtcService.setMicrophoneMuted(true);

      expect(fakeRtcService.isMicrophoneMuted, isTrue);
      expect(fakeRtcService.currentParticipantMediaStates.first.isAudioMuted, isTrue);

      await fakeRtcService.setMicrophoneMuted(false);

      expect(fakeRtcService.isMicrophoneMuted, isFalse);
      expect(fakeRtcService.currentParticipantMediaStates.first.isAudioMuted, isFalse);
    });

    test('camera enable/disable updates local participant', () async {
      await fakeRtcService.joinSession(testSession);

      expect(fakeRtcService.isCameraEnabled, isTrue);
      expect(fakeRtcService.currentParticipantMediaStates.first.isVideoEnabled, isTrue);

      await fakeRtcService.setCameraEnabled(false);

      expect(fakeRtcService.isCameraEnabled, isFalse);
      expect(fakeRtcService.currentParticipantMediaStates.first.isVideoEnabled, isFalse);
    });

    test('switchCamera increments call count', () async {
      expect(fakeRtcService.switchCameraCallCount, 0);
      await fakeRtcService.switchCamera();
      expect(fakeRtcService.switchCameraCallCount, 1);
    });

    test('cleanup disposes service properly and prevents further joins', () async {
      await fakeRtcService.joinSession(testSession);
      await fakeRtcService.dispose();

      expect(fakeRtcService.isDisposed, isTrue);
      expect(fakeRtcService.isJoined, isFalse);
      expect(() => fakeRtcService.joinSession(testSession), throwsStateError);
    });
  });
}
