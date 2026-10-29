import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:collab_tasks/features/calls/data/remote/agora/agora_rtc_service.dart';
import 'package:collab_tasks/features/calls/data/remote/agora/agora_uid_mapper.dart';
import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRtcEngine extends Mock implements RtcEngine {}

class _FakeChannelMediaOptions extends Fake implements ChannelMediaOptions {}

class _FakeVideoEncoderConfiguration extends Fake implements VideoEncoderConfiguration {}

void main() {
  late _MockRtcEngine engine;
  late AgoraUidMapper uidMapper;
  late AgoraRtcService service;

  setUpAll(() {
    registerFallbackValue(_FakeChannelMediaOptions());
    registerFallbackValue(_FakeVideoEncoderConfiguration());
  });

  setUp(() {
    engine = _MockRtcEngine();
    uidMapper = AgoraUidMapper();
    service = AgoraRtcService(appId: 'test-app-id', engine: engine, uidMapper: uidMapper);

    when(() => engine.enableAudio()).thenAnswer((_) async {});
    when(
      () => engine.enableAudioVolumeIndication(
        interval: any(named: 'interval'),
        smooth: any(named: 'smooth'),
        reportVad: any(named: 'reportVad'),
      ),
    ).thenAnswer((_) async {});
    when(() => engine.muteLocalAudioStream(any())).thenAnswer((_) async {});
    when(() => engine.setDefaultAudioRouteToSpeakerphone(any())).thenAnswer((_) async {});
    when(() => engine.setEnableSpeakerphone(any())).thenAnswer((_) async {});
    when(() => engine.enableVideo()).thenAnswer((_) async {});
    when(() => engine.disableVideo()).thenAnswer((_) async {});
    when(() => engine.startPreview()).thenAnswer((_) async {});
    when(() => engine.stopPreview()).thenAnswer((_) async {});
    when(() => engine.setVideoEncoderConfiguration(any())).thenAnswer((_) async {});
    when(() => engine.updateChannelMediaOptions(any())).thenAnswer((_) async {});
    when(
      () => engine.joinChannel(
        token: any(named: 'token'),
        channelId: any(named: 'channelId'),
        uid: any(named: 'uid'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async {});
    when(() => engine.leaveChannel()).thenAnswer((_) async {});
    when(() => engine.disableAudio()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await service.dispose();
  });

  const videoSession = CallSession(
    callId: 'video-call',
    roomId: 'video-room',
    token: 'video-token',
    localUserId: 'user-1',
    extra: {'mediaType': 'video'},
  );
  const audioSession = CallSession(
    callId: 'audio-call',
    roomId: 'audio-room',
    token: 'audio-token',
    localUserId: 'user-1',
    extra: {'mediaType': 'audio'},
  );

  test('video call teardown prevents video publication in the next audio call', () async {
    await service.joinSession(videoSession);
    expect(service.isCameraEnabled, isTrue);

    await service.leaveSession();
    expect(service.isCameraEnabled, isFalse);

    clearInteractions(engine);
    await service.joinSession(audioSession);

    verifyNever(() => engine.enableVideo());
    verifyNever(() => engine.startPreview());
    verifyNever(() => engine.setEnableSpeakerphone(any()));
    verify(() => engine.disableVideo()).called(1);
    final options =
        verify(
              () => engine.joinChannel(
                token: 'audio-token',
                channelId: 'audio-room',
                uid: any(named: 'uid'),
                options: captureAny(named: 'options'),
              ),
            ).captured.single
            as ChannelMediaOptions;
    expect(options.publishCameraTrack, isFalse);
    expect(options.publishMicrophoneTrack, isTrue);
  });

  test('joins with the same stable UID used by the repository token session', () async {
    final participants = uidMapper.mapCallParticipants(
      ['caller@example.com', 'callee@example.com'],
      aliases: {'callee-uid': 'callee@example.com'},
    );
    final localUid = participants['callee-uid']!;
    final session = CallSession(
      callId: 'mapped-call',
      roomId: 'mapped-call',
      token: 'mapped-token',
      localUserId: 'callee-uid',
      extra: {
        'mediaType': 'audio',
        'uid': localUid,
        'participants': participants,
        'participantCanonicalIds': uidMapper.canonicalIdsByIdentity,
      },
    );

    await service.joinSession(session);

    verify(
      () => engine.joinChannel(
        token: 'mapped-token',
        channelId: 'mapped-call',
        uid: localUid,
        options: any(named: 'options'),
      ),
    ).called(1);
    expect(uidMapper.toUserId(participants['caller@example.com']!), 'caller@example.com');
  });

  test('leave resets mute, camera and speaker state before the next session', () async {
    await service.joinSession(videoSession);
    await service.setMicrophoneMuted(true);
    await service.setSpeakerEnabled(true);
    await service.setCameraEnabled(false);
    expect(service.isMicrophoneMuted, isTrue);
    expect(service.isSpeakerEnabled, isTrue);

    await service.leaveSession();

    expect(service.isMicrophoneMuted, isFalse);
    expect(service.isCameraEnabled, isFalse);
    expect(service.isSpeakerEnabled, isFalse);
    verify(() => engine.muteLocalAudioStream(false)).called(2);
    verify(() => engine.setDefaultAudioRouteToSpeakerphone(false)).called(2);
    verifyNever(() => engine.setEnableSpeakerphone(any()));

    await service.joinSession(audioSession);
    expect(service.isMicrophoneMuted, isFalse);
    expect(service.isCameraEnabled, isFalse);
    expect(service.isSpeakerEnabled, isFalse);
    verify(() => engine.muteLocalAudioStream(false)).called(1);
    verify(() => engine.setDefaultAudioRouteToSpeakerphone(false)).called(1);
    verifyNever(() => engine.setEnableSpeakerphone(any()));
  });

  test('leave resets internal state and continues cleanup after an SDK error', () async {
    await service.joinSession(videoSession);
    await service.setMicrophoneMuted(true);
    await service.setSpeakerEnabled(true);
    when(() => engine.stopPreview()).thenThrow(StateError('preview already stopped'));

    await service.leaveSession();

    expect(service.activeSession, isNull);
    expect(service.isMicrophoneMuted, isFalse);
    expect(service.isCameraEnabled, isFalse);
    expect(service.isSpeakerEnabled, isFalse);
    verify(() => engine.leaveChannel()).called(1);
    verify(() => engine.disableVideo()).called(1);
    verify(() => engine.disableAudio()).called(1);
    verifyNever(() => engine.updateChannelMediaOptions(any()));
  });
}
