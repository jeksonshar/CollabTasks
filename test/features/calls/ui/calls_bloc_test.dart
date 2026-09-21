import 'package:bloc_test/bloc_test.dart';
import 'package:collab_tasks/features/calls/data/repositories/in_memory_call_repository.dart';
import 'package:collab_tasks/features/calls/data/rtc/fake_rtc_service.dart';
import 'package:collab_tasks/features/calls/data/services/fake_call_permissions_service.dart';
import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/models/call_status.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_connection_state.dart';
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
import 'package:collab_tasks/features/calls/domain/use_cases/watch_rtc_connection_state_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/watch_rtc_participant_media_states_use_case.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_bloc.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_event.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryCallRepository callRepository;
  late FakeRtcService fakeRtcService;
  late FakeCallPermissionsService fakePermissionsService;

  CallsBloc buildBloc({bool micGranted = true, bool cameraGranted = true}) {
    fakePermissionsService.microphoneGranted = micGranted;
    fakePermissionsService.cameraGranted = cameraGranted;

    return CallsBloc(
      startCallUseCase: StartCallUseCase(callRepository),
      acceptCallUseCase: AcceptCallUseCase(callRepository),
      rejectCallUseCase: RejectCallUseCase(callRepository),
      endCallUseCase: EndCallUseCase(callRepository),
      cancelCallUseCase: CancelCallUseCase(callRepository),
      leaveCallUseCase: LeaveCallUseCase(callRepository),
      inviteParticipantUseCase: InviteParticipantUseCase(callRepository),
      requestCallPermissionsUseCase: RequestCallPermissionsUseCase(fakePermissionsService),
      getCallSessionUseCase: GetCallSessionUseCase(callRepository),
      watchActiveCallUseCase: WatchActiveCallUseCase(callRepository),
      joinRtcSessionUseCase: JoinRtcSessionUseCase(fakeRtcService),
      leaveRtcSessionUseCase: LeaveRtcSessionUseCase(fakeRtcService),
      toggleMicrophoneUseCase: ToggleMicrophoneUseCase(fakeRtcService),
      toggleCameraUseCase: ToggleCameraUseCase(fakeRtcService),
      switchCameraUseCase: SwitchCameraUseCase(fakeRtcService),
      watchRtcConnectionStateUseCase: WatchRtcConnectionStateUseCase(fakeRtcService),
      watchRtcParticipantMediaStatesUseCase: WatchRtcParticipantMediaStatesUseCase(fakeRtcService),
    );
  }

  setUp(() {
    callRepository = InMemoryCallRepository();
    fakeRtcService = FakeRtcService();
    fakePermissionsService = FakeCallPermissionsService();
  });

  tearDown(() async {
    callRepository.dispose();
    await fakeRtcService.dispose();
  });

  group('CallsBloc unit tests', () {
    test('initial state is idle and disconnected', () async {
      final bloc = buildBloc();
      expect(bloc.state.status, CallsStatus.idle);
      expect(bloc.state.rtcConnectionState, RtcConnectionState.disconnected);
      expect(bloc.state.activeCall, isNull);
      await bloc.close();
    });

    blocTest<CallsBloc, CallsState>(
      'StartCallRequested initiates outgoing ringing call when permissions granted',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const StartCallRequested(
          callerId: 'user-caller',
          callerName: 'Caller User',
          calleeIds: ['user-callee'],
          type: CallType.video,
        ),
      ),
      expect: () => [
        isA<CallsState>()
            .having((s) => s.status, 'status', CallsStatus.ringingOutgoing)
            .having((s) => s.currentUserId, 'currentUserId', 'user-caller')
            .having((s) => s.isCameraEnabled, 'isCameraEnabled', isTrue),
        isA<CallsState>()
            .having((s) => s.status, 'status', CallsStatus.ringingOutgoing)
            .having((s) => s.activeCall, 'activeCall', isNotNull)
            .having((s) => s.activeCall?.callerId, 'callerId', 'user-caller')
            .having((s) => s.activeCall?.type, 'type', CallType.video),
      ],
    );

    blocTest<CallsBloc, CallsState>(
      'StartCallRequested emits error when permissions denied',
      build: () => buildBloc(micGranted: false),
      act: (bloc) => bloc.add(
        const StartCallRequested(
          callerId: 'user-caller',
          callerName: 'Caller User',
          calleeIds: ['user-callee'],
          type: CallType.audio,
        ),
      ),
      expect: () => [
        isA<CallsState>()
            .having((s) => s.status, 'status', CallsStatus.error)
            .having((s) => s.errorMessage, 'errorMessage', contains('Microphone permission')),
      ],
    );

    blocTest<CallsBloc, CallsState>(
      'IncomingCallDetected sets status to ringingIncoming',
      build: buildBloc,
      act: (bloc) {
        final incoming = Call(
          id: 'call-in-1',
          callerId: 'user-caller',
          callerName: 'Alice',
          calleeIds: const ['user-callee'],
          type: CallType.audio,
          status: CallStatus.ringing,
          createdAt: DateTime.now(),
        );
        bloc.add(IncomingCallDetected(incoming));
      },
      expect: () => [
        isA<CallsState>()
            .having((s) => s.status, 'status', CallsStatus.ringingIncoming)
            .having((s) => s.activeCall?.callerName, 'callerName', 'Alice'),
      ],
    );

    late Call incomingCall;

    blocTest<CallsBloc, CallsState>(
      'AcceptCallRequested transitions to active and joins RTC session',
      build: buildBloc,
      setUp: () async {
        incomingCall = await callRepository.startCall(
          callerId: 'caller-1',
          callerName: 'Caller 1',
          calleeIds: ['callee-1'],
          type: CallType.audio,
        );
      },
      act: (bloc) {
        bloc.add(AcceptCallRequested(callId: incomingCall.id, userId: 'callee-1'));
      },
      expect: () => [
        isA<CallsState>()
            .having((s) => s.status, 'status', CallsStatus.active)
            .having((s) => s.currentUserId, 'currentUserId', 'callee-1'),
        isA<CallsState>()
            .having((s) => s.status, 'status', CallsStatus.active)
            .having((s) => s.session, 'session', isNotNull),
        isA<CallsState>().having(
          (s) => s.rtcConnectionState,
          'rtcConnectionState',
          RtcConnectionState.connecting,
        ),
        isA<CallsState>().having(
          (s) => s.participantMediaStates,
          'participantMediaStates',
          hasLength(1),
        ),
        isA<CallsState>().having(
          (s) => s.rtcConnectionState,
          'rtcConnectionState',
          RtcConnectionState.connected,
        ),
      ],
      verify: (_) {
        expect(fakeRtcService.joinCallCount, 1);
        expect(fakeRtcService.lastJoinedSession?.localUserId, 'callee-1');
      },
    );

    blocTest<CallsBloc, CallsState>(
      'ToggleMicrophoneRequested toggles mic in state and fake RTC',
      build: buildBloc,
      act: (bloc) => bloc.add(const ToggleMicrophoneRequested()),
      expect: () => [
        isA<CallsState>().having((s) => s.isMicrophoneMuted, 'isMicrophoneMuted', isTrue),
      ],
      verify: (_) {
        expect(fakeRtcService.isMicrophoneMuted, isTrue);
      },
    );

    blocTest<CallsBloc, CallsState>(
      'ToggleCameraRequested toggles camera in state and fake RTC',
      build: buildBloc,
      act: (bloc) => bloc.add(const ToggleCameraRequested()),
      expect: () => [
        isA<CallsState>().having((s) => s.isCameraEnabled, 'isCameraEnabled', isFalse),
      ],
      verify: (_) {
        expect(fakeRtcService.isCameraEnabled, isFalse);
      },
    );

    blocTest<CallsBloc, CallsState>(
      'SwitchCameraRequested calls switchCamera on RTC service',
      build: buildBloc,
      act: (bloc) => bloc.add(const SwitchCameraRequested()),
      verify: (_) {
        expect(fakeRtcService.switchCameraCallCount, 1);
      },
    );

    blocTest<CallsBloc, CallsState>(
      'CancelCallRequested terminates ringing outgoing call and resets state',
      build: buildBloc,
      seed: () => CallsState(
        status: CallsStatus.ringingOutgoing,
        currentUserId: 'user-1',
        activeCall: Call(
          id: 'call-cancel-test',
          callerId: 'user-1',
          callerName: 'User 1',
          calleeIds: const ['user-2'],
          type: CallType.audio,
          status: CallStatus.ringing,
          createdAt: DateTime.now(),
        ),
      ),
      act: (bloc) => bloc.add(const CancelCallRequested()),
      expect: () => [
        isA<CallsState>().having((s) => s.status, 'status', CallsStatus.terminating),
        const CallsState(status: CallsStatus.idle),
      ],
    );

    blocTest<CallsBloc, CallsState>(
      'LeaveCallRequested leaves group call and resets state',
      build: buildBloc,
      seed: () => CallsState(
        status: CallsStatus.active,
        currentUserId: 'user-2',
        activeCall: Call(
          id: 'call-leave-test',
          callerId: 'user-1',
          callerName: 'User 1',
          calleeIds: const ['user-2', 'user-3'],
          type: CallType.audio,
          status: CallStatus.active,
          isGroup: true,
          createdAt: DateTime.now(),
        ),
      ),
      act: (bloc) => bloc.add(const LeaveCallRequested()),
      expect: () => [
        isA<CallsState>().having((s) => s.status, 'status', CallsStatus.terminating),
        const CallsState(status: CallsStatus.idle),
      ],
    );

    blocTest<CallsBloc, CallsState>(
      'AppLifecycleChanged pauses and resumes camera on active video call',
      build: buildBloc,
      seed: () => CallsState(
        status: CallsStatus.active,
        isCameraEnabled: true,
        activeCall: Call(
          id: 'call-lifecycle-test',
          callerId: 'user-1',
          callerName: 'User 1',
          calleeIds: const ['user-2'],
          type: CallType.video,
          status: CallStatus.active,
          createdAt: DateTime.now(),
        ),
      ),
      act: (bloc) {
        bloc.add(const AppLifecycleChanged(AppLifecycleState.paused));
        bloc.add(const AppLifecycleChanged(AppLifecycleState.resumed));
      },
      expect: () => [
        isA<CallsState>().having((s) => s.isCameraEnabled, 'isCameraEnabled', isFalse),
        isA<CallsState>().having((s) => s.isCameraEnabled, 'isCameraEnabled', isTrue),
      ],
    );

    blocTest<CallsBloc, CallsState>(
      'RtcConnectionStateChanged updates rtcConnectionState in state',
      build: buildBloc,
      act: (bloc) => bloc.add(const RtcConnectionStateChanged(RtcConnectionState.reconnecting)),
      expect: () => [
        isA<CallsState>().having(
          (s) => s.rtcConnectionState,
          'rtcConnectionState',
          RtcConnectionState.reconnecting,
        ),
      ],
    );

    blocTest<CallsBloc, CallsState>(
      'EndCallRequested leaves RTC session and resets state to idle',
      build: buildBloc,
      seed: () => CallsState(
        status: CallsStatus.active,
        activeCall: Call(
          id: 'call-end-test',
          callerId: 'user-1',
          callerName: 'User 1',
          calleeIds: const ['user-2'],
          type: CallType.audio,
          status: CallStatus.active,
          createdAt: DateTime.now(),
        ),
      ),
      act: (bloc) => bloc.add(const EndCallRequested()),
      expect: () => [
        isA<CallsState>().having((s) => s.status, 'status', CallsStatus.terminating),
        const CallsState(status: CallsStatus.idle),
      ],
      verify: (_) {
        expect(fakeRtcService.isJoined, isFalse);
      },
    );
  });
}
