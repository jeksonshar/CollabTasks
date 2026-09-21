import 'package:collab_tasks/features/calls/data/repositories/in_memory_call_repository.dart';
import 'package:collab_tasks/features/calls/data/rtc/fake_rtc_service.dart';
import 'package:collab_tasks/features/calls/data/services/fake_call_permissions_service.dart';
import 'package:collab_tasks/features/calls/domain/models/call_participant.dart';
import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
import 'package:collab_tasks/features/calls/domain/models/call_status.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/accept_call_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/cancel_call_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/end_call_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/get_call_session_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/invite_participant_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/join_rtc_session_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/leave_call_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/leave_rtc_session_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/reject_call_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/request_call_permissions_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/start_call_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/switch_camera_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/toggle_camera_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/toggle_microphone_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/watch_active_call_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryCallRepository callRepository;
  late FakeRtcService rtcService;
  late FakeCallPermissionsService permissionsService;

  late StartCallUseCase startCallUseCase;
  late AcceptCallUseCase acceptCallUseCase;
  late RejectCallUseCase rejectCallUseCase;
  late EndCallUseCase endCallUseCase;
  late CancelCallUseCase cancelCallUseCase;
  late LeaveCallUseCase leaveCallUseCase;
  late InviteParticipantUseCase inviteParticipantUseCase;
  late RequestCallPermissionsUseCase requestCallPermissionsUseCase;
  late GetCallSessionUseCase getCallSessionUseCase;
  late WatchActiveCallUseCase watchActiveCallUseCase;
  late JoinRtcSessionUseCase joinRtcSessionUseCase;
  late LeaveRtcSessionUseCase leaveRtcSessionUseCase;
  late ToggleMicrophoneUseCase toggleMicrophoneUseCase;
  late ToggleCameraUseCase toggleCameraUseCase;
  late SwitchCameraUseCase switchCameraUseCase;

  setUp(() {
    callRepository = InMemoryCallRepository();
    rtcService = FakeRtcService();
    permissionsService = FakeCallPermissionsService();

    startCallUseCase = StartCallUseCase(callRepository);
    acceptCallUseCase = AcceptCallUseCase(callRepository);
    rejectCallUseCase = RejectCallUseCase(callRepository);
    endCallUseCase = EndCallUseCase(callRepository);
    cancelCallUseCase = CancelCallUseCase(callRepository);
    leaveCallUseCase = LeaveCallUseCase(callRepository);
    inviteParticipantUseCase = InviteParticipantUseCase(callRepository);
    requestCallPermissionsUseCase = RequestCallPermissionsUseCase(permissionsService);
    getCallSessionUseCase = GetCallSessionUseCase(callRepository);
    watchActiveCallUseCase = WatchActiveCallUseCase(callRepository);
    joinRtcSessionUseCase = JoinRtcSessionUseCase(rtcService);
    leaveRtcSessionUseCase = LeaveRtcSessionUseCase(rtcService);
    toggleMicrophoneUseCase = ToggleMicrophoneUseCase(rtcService);
    toggleCameraUseCase = ToggleCameraUseCase(rtcService);
    switchCameraUseCase = SwitchCameraUseCase(rtcService);
  });

  tearDown(() async {
    callRepository.dispose();
    await rtcService.dispose();
  });

  group('Call Domain UseCases test', () {
    test('StartCallUseCase initiates a call with ringing status', () async {
      final call = await startCallUseCase(
        callerId: 'user-1',
        callerName: 'Alice',
        calleeIds: ['user-2'],
        type: CallType.audio,
      );

      expect(call.callerId, 'user-1');
      expect(call.status, CallStatus.ringing);
      expect(call.participants.length, 2);
    });

    test('AcceptCallUseCase updates call status to active', () async {
      final call = await startCallUseCase(
        callerId: 'user-1',
        callerName: 'Alice',
        calleeIds: ['user-2'],
        type: CallType.audio,
      );

      await acceptCallUseCase(callId: call.id, userId: 'user-2');

      final updated = await callRepository.getCallById(call.id);
      expect(updated?.status, CallStatus.active);
      expect(updated?.startedAt, isNotNull);
    });

    test('RejectCallUseCase sets status to rejected', () async {
      final call = await startCallUseCase(
        callerId: 'user-1',
        callerName: 'Alice',
        calleeIds: ['user-2'],
        type: CallType.audio,
      );

      await rejectCallUseCase(callId: call.id, userId: 'user-2');

      final updated = await callRepository.getCallById(call.id);
      expect(updated?.status, CallStatus.rejected);
      expect(updated?.endedAt, isNotNull);
    });

    test('EndCallUseCase sets status to ended', () async {
      final call = await startCallUseCase(
        callerId: 'user-1',
        callerName: 'Alice',
        calleeIds: ['user-2'],
        type: CallType.audio,
      );

      await endCallUseCase(call.id);

      final updated = await callRepository.getCallById(call.id);
      expect(updated?.status, CallStatus.ended);
      expect(updated?.endedAt, isNotNull);
    });

    test('CancelCallUseCase sets status to cancelled', () async {
      final call = await startCallUseCase(
        callerId: 'user-1',
        callerName: 'Alice',
        calleeIds: ['user-2'],
        type: CallType.audio,
      );

      await cancelCallUseCase(call.id);

      final updated = await callRepository.getCallById(call.id);
      expect(updated?.status, CallStatus.cancelled);
      expect(updated?.endedAt, isNotNull);
    });

    test('LeaveCallUseCase updates participant status and ends call if alone', () async {
      final call = await startCallUseCase(
        callerId: 'user-1',
        callerName: 'Alice',
        calleeIds: ['user-2'],
        type: CallType.audio,
      );
      await acceptCallUseCase(callId: call.id, userId: 'user-2');

      await leaveCallUseCase(callId: call.id, userId: 'user-2');

      final updated = await callRepository.getCallById(call.id);
      expect(updated?.status, CallStatus.ended);
      final participant = updated?.participants.firstWhere((p) => p.userId == 'user-2');
      expect(participant?.status, CallParticipantStatus.left);
    });

    test('InviteParticipantUseCase adds new participant to call', () async {
      final call = await startCallUseCase(
        callerId: 'user-1',
        callerName: 'Alice',
        calleeIds: ['user-2'],
        type: CallType.video,
        isGroup: true,
      );

      await inviteParticipantUseCase(callId: call.id, userId: 'user-3', displayName: 'Charlie');

      final updated = await callRepository.getCallById(call.id);
      expect(updated?.participants.any((p) => p.userId == 'user-3'), isTrue);
      expect(updated?.calleeIds.contains('user-3'), isTrue);
    });

    test('RequestCallPermissionsUseCase respects service grants', () async {
      permissionsService.microphoneGranted = true;
      permissionsService.cameraGranted = true;
      expect(await requestCallPermissionsUseCase(type: CallType.audio), isTrue);
      expect(await requestCallPermissionsUseCase(type: CallType.video), isTrue);

      permissionsService.cameraGranted = false;
      expect(await requestCallPermissionsUseCase(type: CallType.audio), isTrue);
      expect(await requestCallPermissionsUseCase(type: CallType.video), isFalse);

      permissionsService.microphoneGranted = false;
      expect(await requestCallPermissionsUseCase(type: CallType.audio), isFalse);
    });

    test('GetCallSessionUseCase returns valid CallSession', () async {
      final call = await startCallUseCase(
        callerId: 'user-1',
        callerName: 'Alice',
        calleeIds: ['user-2'],
        type: CallType.video,
      );

      final session = await getCallSessionUseCase(callId: call.id, userId: 'user-1');
      expect(session.callId, call.id);
      expect(session.localUserId, 'user-1');
      expect(session.roomId, contains(call.id));
      expect(session.extra['mediaType'], 'video');
    });

    test('WatchActiveCallUseCase emits active call updates', () async {
      final call = await startCallUseCase(
        callerId: 'user-1',
        callerName: 'Alice',
        calleeIds: ['user-2'],
        type: CallType.audio,
      );

      final emissionFuture = watchActiveCallUseCase(call.id).first;
      await acceptCallUseCase(callId: call.id, userId: 'user-2');

      final emitted = await emissionFuture;
      expect(emitted?.status, CallStatus.active);
    });

    test('RTC UseCases control FakeRtcService properly', () async {
      const session = CallSession(
        callId: 'call-1',
        roomId: 'room-1',
        token: 'token-1',
        localUserId: 'user-1',
      );

      await joinRtcSessionUseCase(session);
      expect(rtcService.isJoined, isTrue);

      await toggleMicrophoneUseCase(true);
      expect(rtcService.isMicrophoneMuted, isTrue);

      await toggleCameraUseCase(false);
      expect(rtcService.isCameraEnabled, isFalse);

      await switchCameraUseCase();
      expect(rtcService.switchCameraCallCount, 1);

      await leaveRtcSessionUseCase();
      expect(rtcService.isJoined, isFalse);
    });
  });
}
