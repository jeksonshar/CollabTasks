import 'package:collab_tasks/features/calls/data/rtc/fake_rtc_service.dart';
import 'package:collab_tasks/features/calls/data/services/call_picture_in_picture_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Android audio call configures PiP actions and enters native PiP', () async {
    const methodChannel = MethodChannel('test/call_picture_in_picture');
    const eventChannel = EventChannel('test/call_picture_in_picture/events');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      methodChannel,
      (call) async {
        calls.add(call);
        return switch (call.method) {
          'configureCallActions' ||
          'startCallBackgroundService' ||
          'prepareAudioPictureInPicture' ||
          'enterAudioPictureInPicture' => true,
          _ => null,
        };
      },
    );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null),
    );
    final rtcService = FakeRtcService();
    final service = CallPictureInPictureService(
      rtcService: rtcService,
      platform: TargetPlatform.android,
      methodChannel: methodChannel,
      eventChannel: eventChannel,
    );
    const configuration = CallPictureInPictureConfiguration(
      callId: 'audio-call-1',
      displayName: 'Alex',
      isVideo: false,
      isGroup: true,
      isMicrophoneMuted: false,
    );

    expect(await service.enterPictureInPicture(configuration), isTrue);
    expect(calls.map((call) => call.method), [
      'configureCallActions',
      'startCallBackgroundService',
      'prepareAudioPictureInPicture',
      'enterAudioPictureInPicture',
    ]);
    expect(calls.first.arguments, {'isGroup': true, 'isMicrophoneMuted': false});
    expect(calls[1].arguments, {'displayName': 'Alex'});
    expect(calls[2].arguments, isNull);
    expect(calls.last.arguments, isNull);

    const mutedConfiguration = CallPictureInPictureConfiguration(
      callId: 'audio-call-1',
      displayName: 'Alex',
      isVideo: false,
      isGroup: true,
      isMicrophoneMuted: true,
    );
    expect(await service.prepare(mutedConfiguration), isTrue);
    expect(calls.last.method, 'updateCallMicrophoneState');
    expect(calls.last.arguments, {'isMicrophoneMuted': true});
    expect(calls.where((call) => call.method == 'startCallBackgroundService'), hasLength(1));
    expect(await service.prepare(configuration), isTrue);
    expect(calls.last.method, 'updateCallMicrophoneState');
    expect(calls.last.arguments, {'isMicrophoneMuted': false});

    await service.close();
    expect(calls.map((call) => call.method).toList().sublist(6), [
      'stopCallBackgroundService',
      'dismissCallPictureInPicture',
    ]);
    await rtcService.dispose();
  });

  test('video PiP returns unsupported when the RTC backend has no Agora engine', () async {
    final rtcService = FakeRtcService();
    final service = CallPictureInPictureService(
      rtcService: rtcService,
      platform: TargetPlatform.iOS,
    );
    const configuration = CallPictureInPictureConfiguration(
      callId: 'video-call-2',
      displayName: 'Sam',
      remoteParticipantId: 'remote-user',
      isVideo: true,
      isGroup: false,
    );

    expect(await service.prepare(configuration), isFalse);

    await service.close();
    await rtcService.dispose();
  });

  test('native events decode PiP state and supported call actions', () {
    expect(
      CallPictureInPictureEvent.fromPlatformValue({
        'type': 'modeChanged',
        'isInPictureInPicture': true,
      }),
      isA<CallPictureInPictureEvent>()
          .having((event) => event.type, 'type', CallPictureInPictureEventType.modeChanged)
          .having((event) => event.isInPictureInPicture, 'isInPictureInPicture', isTrue),
    );
    expect(
      CallPictureInPictureEvent.fromPlatformValue({'type': 'action', 'action': 'toggleMicrophone'}),
      isA<CallPictureInPictureEvent>().having(
        (event) => event.action,
        'action',
        CallPictureInPictureAction.toggleMicrophone,
      ),
    );
    expect(
      CallPictureInPictureEvent.fromPlatformValue({'type': 'action', 'action': 'restore'}),
      isNull,
    );
  });
}
