import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:collab_tasks/features/calls/data/repositories/in_memory_call_repository.dart';
import 'package:collab_tasks/features/calls/data/rtc/fake_rtc_service.dart';
import 'package:collab_tasks/features/calls/data/services/fake_call_permissions_service.dart';
import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/models/call_data_entity.dart';
import 'package:collab_tasks/features/calls/domain/models/call_error_type.dart';
import 'package:collab_tasks/features/calls/domain/models/call_participant.dart';
import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
import 'package:collab_tasks/features/calls/domain/models/call_status.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_connection_state.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/accept_call_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/accept_incoming_call_usecase.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/cancel_call_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/decline_incoming_call_usecase.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/end_call_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/get_call_session_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/invite_participant_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/join_rtc_session_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/leave_call_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/leave_rtc_session_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/reject_call_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/request_call_permissions_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/start_call_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/start_incoming_alert_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/start_outgoing_alert_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/stop_call_alert_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/switch_camera_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/toggle_camera_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/toggle_microphone_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/toggle_speaker_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/watch_active_call_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/watch_incoming_calls_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/watch_rtc_connection_state_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/watch_rtc_participant_media_states_use_case.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_bloc.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_event.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ─── Моки alert use-case'ов ───────────────────────────────────────────────────

class MockStartIncomingAlertUseCase extends Mock implements StartIncomingAlertUseCase {}

class MockStartOutgoingAlertUseCase extends Mock implements StartOutgoingAlertUseCase {}

class MockStopCallAlertUseCase extends Mock implements StopCallAlertUseCase {}

class MockAcceptCallUseCase extends Mock implements AcceptCallUseCase {}

class MockAcceptIncomingCallUseCase extends Mock implements AcceptIncomingCallUseCase {}

class MockDeclineIncomingCallUseCase extends Mock implements DeclineIncomingCallUseCase {}

class MockRejectCallUseCase extends Mock implements RejectCallUseCase {}

class MockCancelCallUseCase extends Mock implements CancelCallUseCase {}

class MockEndCallUseCase extends Mock implements EndCallUseCase {}

class _CountingCallRepository extends InMemoryCallRepository {
  int startCallCount = 0;

  @override
  Future<Call> startCall({
    String? callId,
    required String callerId,
    required String callerName,
    String? callerAvatarUrl,
    required List<String> calleeIds,
    required CallType type,
    bool isGroup = false,
    String? groupId,
  }) {
    startCallCount++;
    return super.startCall(
      callId: callId,
      callerId: callerId,
      callerName: callerName,
      callerAvatarUrl: callerAvatarUrl,
      calleeIds: calleeIds,
      type: type,
      isGroup: isGroup,
      groupId: groupId,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(
      const CallDataEntity(
        callId: 'fallback',
        displayName: 'Fallback',
        handle: '',
        agoraChannel: '',
        token: '',
        callerId: '',
        callType: CallType.audio,
      ),
    );
  });

  late InMemoryCallRepository callRepository;
  late FakeRtcService fakeRtcService;
  late FakeCallPermissionsService fakePermissionsService;

  CallsBloc buildBloc({
    bool micGranted = true,
    bool cameraGranted = true,
    StartCallUseCase? startCallUseCase,
    AcceptCallUseCase? acceptCallUseCase,
    AcceptIncomingCallUseCase? acceptIncomingCallUseCase,
    DeclineIncomingCallUseCase? declineIncomingCallUseCase,
    RejectCallUseCase? rejectCallUseCase,
    CancelCallUseCase? cancelCallUseCase,
    EndCallUseCase? endCallUseCase,
    StartIncomingAlertUseCase? startIncomingAlertUseCase,
    StartOutgoingAlertUseCase? startOutgoingAlertUseCase,
    StopCallAlertUseCase? stopCallAlertUseCase,
  }) {
    fakePermissionsService
      ..microphoneGranted = micGranted
      ..cameraGranted = cameraGranted;

    return CallsBloc(
      startCallUseCase: startCallUseCase ?? StartCallUseCase(callRepository),
      acceptCallUseCase: acceptCallUseCase ?? AcceptCallUseCase(callRepository),
      acceptIncomingCallUseCase: acceptIncomingCallUseCase,
      declineIncomingCallUseCase: declineIncomingCallUseCase,
      rejectCallUseCase: rejectCallUseCase ?? RejectCallUseCase(callRepository),
      endCallUseCase: endCallUseCase ?? EndCallUseCase(callRepository),
      cancelCallUseCase: cancelCallUseCase ?? CancelCallUseCase(callRepository),
      leaveCallUseCase: LeaveCallUseCase(callRepository),
      inviteParticipantUseCase: InviteParticipantUseCase(callRepository),
      requestCallPermissionsUseCase: RequestCallPermissionsUseCase(fakePermissionsService),
      getCallSessionUseCase: GetCallSessionUseCase(callRepository),
      watchActiveCallUseCase: WatchActiveCallUseCase(callRepository),
      watchIncomingCallsUseCase: WatchIncomingCallsUseCase(callRepository),
      joinRtcSessionUseCase: JoinRtcSessionUseCase(fakeRtcService),
      leaveRtcSessionUseCase: LeaveRtcSessionUseCase(fakeRtcService),
      toggleMicrophoneUseCase: ToggleMicrophoneUseCase(fakeRtcService),
      toggleCameraUseCase: ToggleCameraUseCase(fakeRtcService),
      switchCameraUseCase: SwitchCameraUseCase(fakeRtcService),
      watchRtcConnectionStateUseCase: WatchRtcConnectionStateUseCase(fakeRtcService),
      watchRtcParticipantMediaStatesUseCase: WatchRtcParticipantMediaStatesUseCase(fakeRtcService),
      toggleSpeakerUseCase: ToggleSpeakerUseCase(fakeRtcService),
      startIncomingAlertUseCase: startIncomingAlertUseCase,
      startOutgoingAlertUseCase: startOutgoingAlertUseCase,
      stopCallAlertUseCase: stopCallAlertUseCase,
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

  Call incomingCall(String id, {String callerId = 'caller', String calleeId = 'callee'}) => Call(
    id: id,
    callerId: callerId,
    callerName: 'Caller',
    calleeIds: [calleeId],
    type: CallType.audio,
    status: CallStatus.ringing,
    createdAt: DateTime.now(),
  );

  group('CallsBloc terminal transitions', () {
    test('a rejected user can receive the caller back immediately', () async {
      final bloc = buildBloc()..add(const ListenIncomingCallsStarted('callee'));
      await bloc.stream.firstWhere((state) => state.currentUserId == 'callee');

      bloc.add(IncomingCallDetected(incomingCall('first-call')));
      await bloc.stream.firstWhere((state) => state.status == CallsStatus.ringingIncoming);
      bloc.add(const RejectCallRequested(callId: 'first-call', userId: 'callee'));
      await bloc.stream.firstWhere((state) => state.status == CallsStatus.idle);

      bloc.add(
        IncomingCallDetected(incomingCall('callback', callerId: 'callee', calleeId: 'caller')),
      );
      final nextCall = await bloc.stream.firstWhere(
        (state) => state.status == CallsStatus.ringingIncoming,
      );
      expect(nextCall.activeCall?.id, 'callback');
      expect(nextCall.currentUserId, 'callee');
      await bloc.close();
    });

    test('outgoing timeout clears state and allows a new incoming call', () async {
      final bloc = buildBloc()
        ..add(
          const StartCallRequested(
            callerId: 'caller',
            callerName: 'Caller',
            calleeIds: ['callee'],
            type: CallType.audio,
          ),
        );
      await bloc.stream.firstWhere(
        (state) => state.status == CallsStatus.ringingOutgoing && state.activeCall != null,
      );
      bloc.add(const CallTimeoutOccurred());
      final timedOut = await bloc.stream.firstWhere(
        (state) => state.status == CallsStatus.idle && state.errorType == CallErrorType.callTimeout,
      );
      expect(timedOut.activeCall, isNull);
      expect(timedOut.session, isNull);

      bloc.add(IncomingCallDetected(incomingCall('after-timeout')));
      expect(
        (await bloc.stream.firstWhere(
          (state) => state.status == CallsStatus.ringingIncoming,
        )).activeCall?.id,
        'after-timeout',
      );
      await bloc.close();
    });

    test('permission denial while accepting does not block the next incoming call', () async {
      final bloc = buildBloc(micGranted: false)..add(const ListenIncomingCallsStarted('callee'));
      await bloc.stream.firstWhere((state) => state.currentUserId == 'callee');
      bloc.add(IncomingCallDetected(incomingCall('denied-call')));
      await bloc.stream.firstWhere((state) => state.status == CallsStatus.ringingIncoming);
      bloc.add(const AcceptCallRequested(callId: 'denied-call', userId: 'callee'));
      final denied = await bloc.stream.firstWhere(
        (state) => state.status == CallsStatus.idle && state.errorType != null,
      );
      expect(denied.currentUserId, 'callee');
      expect(denied.activeCall, isNull);
      expect(denied.session, isNull);

      bloc.add(IncomingCallDetected(incomingCall('next-call')));
      expect(
        (await bloc.stream.firstWhere(
          (state) => state.status == CallsStatus.ringingIncoming,
        )).activeCall?.id,
        'next-call',
      );
      await bloc.close();
    });

    test('accept request failure does not block the next incoming call', () async {
      final acceptCallUseCase = MockAcceptCallUseCase();
      when(
        () => acceptCallUseCase(callId: 'failed-accept', userId: 'callee'),
      ).thenThrow(StateError('accept failed'));
      final bloc = buildBloc(acceptCallUseCase: acceptCallUseCase)
        ..add(const ListenIncomingCallsStarted('callee'));
      await bloc.stream.firstWhere((state) => state.currentUserId == 'callee');
      bloc.add(IncomingCallDetected(incomingCall('failed-accept')));
      await bloc.stream.firstWhere((state) => state.status == CallsStatus.ringingIncoming);
      bloc.add(const AcceptCallRequested(callId: 'failed-accept', userId: 'callee'));
      final failed = await bloc.stream.firstWhere(
        (state) => state.status == CallsStatus.idle && state.errorType == CallErrorType.unknown,
      );
      expect(failed.currentUserId, 'callee');
      expect(failed.activeCall, isNull);
      expect(failed.session, isNull);

      bloc.add(IncomingCallDetected(incomingCall('after-failed-accept')));
      expect(
        (await bloc.stream.firstWhere(
          (state) => state.status == CallsStatus.ringingIncoming,
        )).activeCall?.id,
        'after-failed-accept',
      );
      await bloc.close();
    });

    test('accepted call payload survives copyWith for resume navigation recovery', () {
      const callData = CallDataEntity(
        callId: 'accepted-call',
        displayName: 'Caller',
        handle: 'caller@example.com',
        agoraChannel: 'room-1',
        token: 'token',
        callerId: 'caller@example.com',
        calleeId: 'callee',
        callType: CallType.audio,
      );
      const session = CallSession(
        callId: 'accepted-call',
        roomId: 'room-1',
        token: 'token',
        localUserId: 'callee@example.com',
      );
      const accepted = CallAcceptedState(
        callData: callData,
        session: session,
        currentUserId: 'callee@example.com',
      );

      final stateAfterResume = accepted.copyWith(
        rtcConnectionState: RtcConnectionState.reconnecting,
      );
      expect(stateAfterResume, isNot(isA<CallAcceptedState>()));
      expect(stateAfterResume.acceptedCallData?.callId, 'accepted-call');
    });
  });

  group('CallsBloc lifecycle concurrency', () {
    test('two quick start requests create only one call', () async {
      final countingRepository = _CountingCallRepository();
      callRepository = countingRepository;
      final bloc = buildBloc();
      const request = StartCallRequested(
        callId: 'single-start',
        callerId: 'caller',
        callerName: 'Caller',
        calleeIds: ['callee'],
        type: CallType.audio,
      );

      bloc
        ..add(request)
        ..add(request);
      await bloc.stream.firstWhere(
        (state) => state.status == CallsStatus.ringingOutgoing && state.activeCall != null,
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(countingRepository.startCallCount, 1);
      await bloc.close();
    });

    test('Accept wins over a concurrent Decline for the same call', () async {
      await callRepository.startCall(
        callId: 'racing-call',
        callerId: 'caller',
        callerName: 'Caller',
        calleeIds: const ['callee'],
        type: CallType.audio,
      );
      final acceptCallUseCase = MockAcceptCallUseCase();
      final rejectCallUseCase = MockRejectCallUseCase();
      final acceptStarted = Completer<void>();
      final finishAccept = Completer<void>();
      when(() => acceptCallUseCase(callId: 'racing-call', userId: 'callee')).thenAnswer((_) async {
        acceptStarted.complete();
        await finishAccept.future;
      });
      final bloc = buildBloc(
        acceptCallUseCase: acceptCallUseCase,
        rejectCallUseCase: rejectCallUseCase,
      )..add(const ListenIncomingCallsStarted('callee'));
      await bloc.stream.firstWhere((state) => state.currentUserId == 'callee');
      bloc.add(IncomingCallDetected(incomingCall('racing-call')));
      await bloc.stream.firstWhere((state) => state.status == CallsStatus.ringingIncoming);

      bloc.add(const AcceptCallRequested(callId: 'racing-call', userId: 'callee'));
      await acceptStarted.future;
      bloc.add(const RejectCallRequested(callId: 'racing-call', userId: 'callee'));
      finishAccept.complete();
      await bloc.stream.firstWhere((state) => state is CallAcceptedState);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      verify(() => acceptCallUseCase(callId: 'racing-call', userId: 'callee')).called(1);
      verifyNever(() => rejectCallUseCase(callId: 'racing-call', userId: 'callee'));
      expect(bloc.state.status, CallsStatus.active);
      await bloc.close();
    });

    test('duplicate Cancel and End execute each terminal action once', () async {
      final cancelCallUseCase = MockCancelCallUseCase();
      final endCallUseCase = MockEndCallUseCase();
      final cancelStarted = Completer<void>();
      final finishCancel = Completer<void>();
      when(() => cancelCallUseCase('cancel-once')).thenAnswer((_) async {
        cancelStarted.complete();
        await finishCancel.future;
      });
      when(() => endCallUseCase('end-once')).thenAnswer((_) async {});
      final bloc = buildBloc(cancelCallUseCase: cancelCallUseCase, endCallUseCase: endCallUseCase)
        ..add(
          const StartCallRequested(
            callId: 'cancel-once',
            callerId: 'caller',
            callerName: 'Caller',
            calleeIds: ['callee'],
            type: CallType.audio,
          ),
        );
      await bloc.stream.firstWhere((state) => state.activeCall?.id == 'cancel-once');
      bloc
        ..add(const CancelCallRequested(callId: 'cancel-once'))
        ..add(const CancelCallRequested(callId: 'cancel-once'))
        ..add(const EndCallRequested(callId: 'cancel-once'));
      await cancelStarted.future;
      finishCancel.complete();
      await bloc.stream.firstWhere(
        (state) => state.status == CallsStatus.idle && state.terminalCallId == 'cancel-once',
      );
      bloc.add(const CancelCallRequested(callId: 'cancel-once'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      verify(() => cancelCallUseCase('cancel-once')).called(1);
      verifyNever(() => endCallUseCase('cancel-once'));

      bloc.add(
        const StartCallRequested(
          callId: 'end-once',
          callerId: 'caller',
          callerName: 'Caller',
          calleeIds: ['callee'],
          type: CallType.audio,
        ),
      );
      await bloc.stream.firstWhere((state) => state.activeCall?.id == 'end-once');
      bloc
        ..add(const EndCallRequested(callId: 'end-once'))
        ..add(const EndCallRequested(callId: 'end-once'));
      await bloc.stream.firstWhere(
        (state) => state.status == CallsStatus.idle && state.terminalCallId == 'end-once',
      );
      bloc.add(const EndCallRequested(callId: 'end-once'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      verify(() => endCallUseCase('end-once')).called(1);
      await bloc.close();
    });

    test('duplicate CallKit Accept events invoke the accept use case once', () async {
      final acceptIncomingCallUseCase = MockAcceptIncomingCallUseCase();
      final acceptStarted = Completer<void>();
      final finishAccept = Completer<CallSession?>();
      const callData = CallDataEntity(
        callId: 'callkit-accept-once',
        displayName: 'Caller',
        handle: 'caller@example.com',
        agoraChannel: 'channel',
        token: 'token',
        callerId: 'caller@example.com',
        calleeId: 'callee',
        callType: CallType.audio,
      );
      const nativeAccept = CallEventActionCallAccept(
        CallKitParams(
          id: 'callkit-accept-once',
          nameCaller: 'Caller',
          handle: 'caller@example.com',
          type: 0,
          extra: {
            'agoraChannel': 'channel',
            'token': 'token',
            'callerId': 'caller@example.com',
            'calleeId': 'callee',
          },
        ),
      );
      when(
        () => acceptIncomingCallUseCase(
          callData: any(named: 'callData'),
          userId: 'callee',
        ),
      ).thenAnswer((_) {
        acceptStarted.complete();
        return finishAccept.future;
      });
      final bloc = buildBloc(acceptIncomingCallUseCase: acceptIncomingCallUseCase)
        ..add(const ListenIncomingCallsStarted('callee'));
      await bloc.stream.firstWhere((state) => state.currentUserId == 'callee');

      bloc
        ..add(const CallKitEventReceived(nativeAccept))
        ..add(const CallKitEventReceived(nativeAccept))
        ..add(const CallKitAccepted(callData));
      await acceptStarted.future;
      finishAccept.complete(
        const CallSession(
          callId: 'callkit-accept-once',
          roomId: 'channel',
          token: 'token',
          localUserId: 'callee',
        ),
      );
      await bloc.stream.firstWhere((state) => state is CallAcceptedState);
      verify(
        () => acceptIncomingCallUseCase(
          callData: any(named: 'callData'),
          userId: 'callee',
        ),
      ).called(1);
      await bloc.close();
    });

    test('duplicate CallKit Decline events invoke the decline use case once', () async {
      final declineIncomingCallUseCase = MockDeclineIncomingCallUseCase();
      final declineStarted = Completer<void>();
      final finishDecline = Completer<void>();
      const callData = CallDataEntity(
        callId: 'callkit-decline-once',
        displayName: 'Caller',
        handle: 'caller@example.com',
        agoraChannel: 'channel',
        token: 'token',
        callerId: 'caller@example.com',
        calleeId: 'callee',
        callType: CallType.audio,
      );
      when(() => declineIncomingCallUseCase(callId: callData.callId, userId: 'callee')).thenAnswer((
        _,
      ) async {
        declineStarted.complete();
        await finishDecline.future;
      });
      final bloc = buildBloc(declineIncomingCallUseCase: declineIncomingCallUseCase)
        ..add(const ListenIncomingCallsStarted('callee'));
      await bloc.stream.firstWhere((state) => state.currentUserId == 'callee');

      const nativeDecline = CallEventActionCallDecline(
        CallKitParams(
          id: 'callkit-decline-once',
          nameCaller: 'Caller',
          handle: 'caller@example.com',
          type: 0,
          extra: {
            'agoraChannel': 'channel',
            'token': 'token',
            'callerId': 'caller@example.com',
            'calleeId': 'callee',
          },
        ),
      );
      bloc
        ..add(const CallKitEventReceived(nativeDecline))
        ..add(const CallKitEventReceived(nativeDecline))
        ..add(const CallKitDeclined(callData));
      await declineStarted.future;
      finishDecline.complete();
      await bloc.stream.firstWhere(
        (state) => state.status == CallsStatus.idle && state.terminalCallId == callData.callId,
      );
      verify(() => declineIncomingCallUseCase(callId: callData.callId, userId: 'callee')).called(1);
      await bloc.close();
    });

    test('stale active-call and CallKit terminal events cannot clear a newer call', () async {
      final declineIncomingCallUseCase = MockDeclineIncomingCallUseCase();
      final bloc = buildBloc(declineIncomingCallUseCase: declineIncomingCallUseCase)
        ..add(
          const StartCallRequested(
            callId: 'current-call',
            callerId: 'caller',
            callerName: 'Caller',
            calleeIds: ['callee'],
            type: CallType.audio,
          ),
        );
      await bloc.stream.firstWhere((state) => state.activeCall?.id == 'current-call');

      bloc
        ..add(const ActiveCallUpdated(null, watchedCallId: 'old-call'))
        ..add(const ActiveCallUpdated(null, watchedCallId: 'current-call', watchGeneration: 0))
        ..add(
          const CallKitDeclined(
            CallDataEntity(
              callId: 'old-call',
              displayName: 'Old caller',
              handle: 'old@example.com',
              agoraChannel: 'old-channel',
              token: 'old-token',
              callerId: 'old@example.com',
              calleeId: 'callee',
              callType: CallType.audio,
            ),
          ),
        )
        ..add(const EndCallRequested(callId: 'old-call'));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(bloc.state.activeCall?.id, 'current-call');
      expect(bloc.state.status, CallsStatus.ringingOutgoing);
      verifyNever(() => declineIncomingCallUseCase(callId: 'old-call', userId: 'callee'));
      await bloc.close();
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Группа 1 — базовые тесты (без алертов)
  // ═══════════════════════════════════════════════════════════════════════════

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
            .having((s) => s.status, 'status', CallsStatus.idle)
            .having((s) => s.errorType, 'errorType', CallErrorType.permissionDeniedAudio),
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

    blocTest<CallsBloc, CallsState>(
      'IncomingCallDetected sets status to ringingIncoming for active call with ringing participant',
      build: buildBloc,
      act: (bloc) {
        final incoming = Call(
          id: 'call-in-group-1',
          callerId: 'user-caller',
          callerName: 'Alice',
          calleeIds: const ['user-callee'],
          type: CallType.audio,
          status: CallStatus.active,
          isGroup: true,
          participants: const [
            CallParticipant(
              userId: 'user-caller',
              displayName: 'Alice',
              status: CallParticipantStatus.connected,
              role: CallParticipantRole.host,
            ),
            CallParticipant(
              userId: 'user-callee',
              displayName: 'Bob',
              status: CallParticipantStatus.ringing,
              role: CallParticipantRole.participant,
            ),
          ],
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
        isA<CallsState>().having((s) => s.status, 'status', CallsStatus.idle),
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
        isA<CallsState>().having((s) => s.status, 'status', CallsStatus.idle),
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
        bloc
          ..add(const AppLifecycleChanged(AppLifecycleState.paused))
          ..add(const AppLifecycleChanged(AppLifecycleState.resumed));
      },
      expect: () => [
        isA<CallsState>().having((s) => s.isCameraEnabled, 'isCameraEnabled', isFalse),
        isA<CallsState>().having((s) => s.isCameraEnabled, 'isCameraEnabled', isTrue),
      ],
    );

    blocTest<CallsBloc, CallsState>(
      'system pause does not re-enable a camera disabled manually by the user',
      build: buildBloc,
      seed: () => CallsState(
        status: CallsStatus.active,
        isCameraEnabled: true,
        activeCall: Call(
          id: 'call-manual-camera-test',
          callerId: 'user-1',
          callerName: 'User 1',
          calleeIds: const ['user-2'],
          type: CallType.video,
          status: CallStatus.active,
          createdAt: DateTime.now(),
        ),
      ),
      act: (bloc) {
        bloc
          ..add(const ToggleCameraRequested())
          ..add(const AppLifecycleChanged(AppLifecycleState.paused))
          ..add(const AppLifecycleChanged(AppLifecycleState.resumed));
      },
      expect: () => [
        isA<CallsState>()
            .having((s) => s.isCameraEnabled, 'isCameraEnabled', isFalse)
            .having((s) => s.isCameraManuallyDisabled, 'isCameraManuallyDisabled', isTrue),
      ],
      verify: (_) {
        expect(fakeRtcService.isCameraEnabled, isFalse);
      },
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
        isA<CallEndedState>()
            .having((s) => s.status, 'status', CallsStatus.idle)
            .having((s) => s.activeCall, 'activeCall', isNull)
            .having((s) => s.session, 'session', isNull),
      ],
      verify: (_) {
        expect(fakeRtcService.isJoined, isFalse);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Группа 2 — взаимодействие Bloc с CallAlertService через use-case'ы
  // ═══════════════════════════════════════════════════════════════════════════

  group('CallsBloc — call alert interactions', () {
    late MockStartIncomingAlertUseCase mockStartIncoming;
    late MockStartOutgoingAlertUseCase mockStartOutgoing;
    late MockStopCallAlertUseCase mockStop;

    /// Возвращает Bloc с подключёнными моками алертов.
    CallsBloc buildAlertBloc({bool micGranted = true}) {
      return buildBloc(
        micGranted: micGranted,
        startIncomingAlertUseCase: mockStartIncoming,
        startOutgoingAlertUseCase: mockStartOutgoing,
        stopCallAlertUseCase: mockStop,
      );
    }

    setUp(() {
      mockStartIncoming = MockStartIncomingAlertUseCase();
      mockStartOutgoing = MockStartOutgoingAlertUseCase();
      mockStop = MockStopCallAlertUseCase();

      // По умолчанию все alert-методы выполняются без ошибок.
      when(() => mockStartIncoming.call()).thenAnswer((_) async {});
      when(() => mockStartOutgoing.call()).thenAnswer((_) async {});
      when(() => mockStop.call()).thenAnswer((_) async {});
    });

    // ── Исходящий звонок ───────────────────────────────────────────────────

    blocTest<CallsBloc, CallsState>(
      'StartCallRequested вызывает StartOutgoingAlertUseCase',
      build: buildAlertBloc,
      act: (bloc) => bloc.add(
        const StartCallRequested(
          callerId: 'user-1',
          callerName: 'User 1',
          calleeIds: ['user-2'],
          type: CallType.audio,
        ),
      ),
      verify: (_) {
        verify(() => mockStartOutgoing.call()).called(1);
      },
    );

    blocTest<CallsBloc, CallsState>(
      'StartCallRequested не вызывает StartOutgoingAlertUseCase при отказе в разрешениях',
      build: () => buildAlertBloc(micGranted: false),
      act: (bloc) => bloc.add(
        const StartCallRequested(
          callerId: 'user-1',
          callerName: 'User 1',
          calleeIds: ['user-2'],
          type: CallType.audio,
        ),
      ),
      verify: (_) {
        verifyNever(() => mockStartOutgoing.call());
        // StopCallAlertUseCase вызывается при ошибке разрешений (cleanup).
        verify(() => mockStop.call()).called(greaterThanOrEqualTo(1));
      },
    );

    // ── Входящий звонок ────────────────────────────────────────────────────

    blocTest<CallsBloc, CallsState>(
      'IncomingCallDialogOpened вызывает StartIncomingAlertUseCase',
      build: buildAlertBloc,
      seed: () {
        final call = Call(
          id: 'call-alert-in',
          callerId: 'user-2',
          callerName: 'Bob',
          calleeIds: const ['user-1'],
          type: CallType.audio,
          status: CallStatus.ringing,
          createdAt: DateTime.now(),
        );
        return CallsState(status: CallsStatus.ringingIncoming, activeCall: call);
      },
      act: (bloc) => bloc.add(const IncomingCallDialogOpened('call-alert-in')),
      verify: (_) {
        verify(() => mockStartIncoming.call()).called(1);
      },
    );

    blocTest<CallsBloc, CallsState>(
      'IncomingCallDialogOpened игнорируется, если callId не совпадает с активным звонком',
      build: buildAlertBloc,
      seed: () {
        final call = Call(
          id: 'call-alert-in',
          callerId: 'user-2',
          callerName: 'Bob',
          calleeIds: const ['user-1'],
          type: CallType.audio,
          status: CallStatus.ringing,
          createdAt: DateTime.now(),
        );
        return CallsState(status: CallsStatus.ringingIncoming, activeCall: call);
      },
      act: (bloc) => bloc.add(const IncomingCallDialogOpened('wrong-call-id')),
      verify: (_) {
        verifyNever(() => mockStartIncoming.call());
      },
    );

    blocTest<CallsBloc, CallsState>(
      'IncomingCallDialogOpened игнорируется, если статус не ringingIncoming',
      build: buildAlertBloc,
      // seed по умолчанию — idle
      act: (bloc) => bloc.add(const IncomingCallDialogOpened('call-alert-in')),
      verify: (_) {
        verifyNever(() => mockStartIncoming.call());
      },
    );

    // ── Завершение звонка → алерт должен остановиться ────────────────────

    blocTest<CallsBloc, CallsState>(
      'RejectCallRequested вызывает StopCallAlertUseCase',
      build: buildAlertBloc,
      seed: () {
        final call = Call(
          id: 'call-reject',
          callerId: 'user-2',
          callerName: 'Bob',
          calleeIds: const ['user-1'],
          type: CallType.audio,
          status: CallStatus.ringing,
          createdAt: DateTime.now(),
        );
        return CallsState(status: CallsStatus.ringingIncoming, activeCall: call);
      },
      act: (bloc) => bloc.add(const RejectCallRequested(callId: 'call-reject', userId: 'user-1')),
      verify: (_) {
        verify(() => mockStop.call()).called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<CallsBloc, CallsState>(
      'AcceptCallRequested вызывает StopCallAlertUseCase перед вступлением в звонок',
      build: buildAlertBloc,
      setUp: () async {
        // Создаём звонок в репозитории, чтобы getCallSession() не упал.
        await callRepository.startCall(
          callerId: 'user-2',
          callerName: 'Bob',
          calleeIds: ['user-1'],
          type: CallType.audio,
          callId: 'call-accept',
        );
      },
      seed: () {
        final call = Call(
          id: 'call-accept',
          callerId: 'user-2',
          callerName: 'Bob',
          calleeIds: const ['user-1'],
          type: CallType.audio,
          status: CallStatus.ringing,
          createdAt: DateTime.now(),
        );
        return CallsState(status: CallsStatus.ringingIncoming, activeCall: call);
      },
      act: (bloc) => bloc.add(const AcceptCallRequested(callId: 'call-accept', userId: 'user-1')),
      verify: (_) {
        // stop() должен быть вызван минимум один раз.
        verify(() => mockStop.call()).called(greaterThanOrEqualTo(1));
        // startIncoming при этом НЕ должен быть вызван.
        verifyNever(() => mockStartIncoming.call());
      },
    );

    blocTest<CallsBloc, CallsState>(
      'EndCallRequested вызывает StopCallAlertUseCase',
      build: buildAlertBloc,
      seed: () => CallsState(
        status: CallsStatus.active,
        activeCall: Call(
          id: 'call-end',
          callerId: 'user-1',
          callerName: 'User 1',
          calleeIds: const ['user-2'],
          type: CallType.audio,
          status: CallStatus.active,
          createdAt: DateTime.now(),
        ),
      ),
      act: (bloc) => bloc.add(const EndCallRequested()),
      verify: (_) {
        verify(() => mockStop.call()).called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<CallsBloc, CallsState>(
      'CancelCallRequested вызывает StopCallAlertUseCase',
      build: buildAlertBloc,
      seed: () => CallsState(
        status: CallsStatus.ringingOutgoing,
        currentUserId: 'user-1',
        activeCall: Call(
          id: 'call-cancel',
          callerId: 'user-1',
          callerName: 'User 1',
          calleeIds: const ['user-2'],
          type: CallType.audio,
          status: CallStatus.ringing,
          createdAt: DateTime.now(),
        ),
      ),
      act: (bloc) => bloc.add(const CancelCallRequested()),
      verify: (_) {
        verify(() => mockStop.call()).called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<CallsBloc, CallsState>(
      'CallTimeoutOccurred вызывает StopCallAlertUseCase',
      build: buildAlertBloc,
      seed: () => CallsState(
        status: CallsStatus.ringingOutgoing,
        activeCall: Call(
          id: 'call-timeout',
          callerId: 'user-1',
          callerName: 'User 1',
          calleeIds: const ['user-2'],
          type: CallType.audio,
          status: CallStatus.ringing,
          createdAt: DateTime.now(),
        ),
      ),
      act: (bloc) => bloc.add(const CallTimeoutOccurred()),
      expect: () => [
        isA<CallsState>()
            .having((s) => s.status, 'status', CallsStatus.idle)
            .having((s) => s.errorType, 'errorType', CallErrorType.callTimeout)
            .having((s) => s.activeCall, 'activeCall', isNull)
            .having((s) => s.session, 'session', isNull),
      ],
      verify: (_) {
        verify(() => mockStop.call()).called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<CallsBloc, CallsState>(
      'ActiveCallUpdated(null) вызывает StopCallAlertUseCase',
      build: buildAlertBloc,
      seed: () => CallsState(
        status: CallsStatus.ringingOutgoing,
        activeCall: Call(
          id: 'call-null',
          callerId: 'user-1',
          callerName: 'User 1',
          calleeIds: const ['user-2'],
          type: CallType.audio,
          status: CallStatus.ringing,
          createdAt: DateTime.now(),
        ),
      ),
      act: (bloc) => bloc.add(const ActiveCallUpdated(null)),
      expect: () => [
        isA<CallsState>()
            .having((s) => s.status, 'status', CallsStatus.idle)
            .having((s) => s.activeCall, 'activeCall', isNull)
            .having((s) => s.currentUserId, 'currentUserId', isNull),
      ],
      verify: (_) {
        verify(() => mockStop.call()).called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<CallsBloc, CallsState>(
      'ActiveCallUpdated со статусом rejected вызывает StopCallAlertUseCase',
      build: buildAlertBloc,
      seed: () {
        final call = Call(
          id: 'call-rejected',
          callerId: 'user-1',
          callerName: 'User 1',
          calleeIds: const ['user-2'],
          type: CallType.audio,
          status: CallStatus.ringing,
          createdAt: DateTime.now(),
        );
        return CallsState(status: CallsStatus.ringingOutgoing, activeCall: call);
      },
      act: (bloc) => bloc.add(
        ActiveCallUpdated(
          Call(
            id: 'call-rejected',
            callerId: 'user-1',
            callerName: 'User 1',
            calleeIds: const ['user-2'],
            type: CallType.audio,
            status: CallStatus.rejected,
            createdAt: DateTime.now(),
          ),
        ),
      ),
      verify: (_) {
        verify(() => mockStop.call()).called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<CallsBloc, CallsState>(
      'StopCallAlertRequested напрямую вызывает StopCallAlertUseCase',
      build: buildAlertBloc,
      act: (bloc) => bloc.add(const StopCallAlertRequested()),
      verify: (_) {
        // Минимум 1 раз через _onStopCallAlertRequested.
        // bloc_test teardown вызывает close() → _cleanup() → stop() ещё раз,
        // поэтому используем greaterThanOrEqualTo вместо точного called(1).
        verify(() => mockStop.call()).called(greaterThanOrEqualTo(1));
      },
    );

    test('close() вызывает StopCallAlertUseCase через _cleanup()', () async {
      final bloc = buildAlertBloc();
      await bloc.close();
      verify(() => mockStop.call()).called(greaterThanOrEqualTo(1));
    });
  });
}
