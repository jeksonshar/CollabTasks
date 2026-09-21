import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/calls/data/repositories/in_memory_call_repository.dart';
import 'package:collab_tasks/features/calls/data/rtc/fake_rtc_service.dart';
import 'package:collab_tasks/features/calls/data/rtc/fake_video_view_factory.dart';
import 'package:collab_tasks/features/calls/data/services/fake_call_permissions_service.dart';
import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/models/call_participant.dart';
import 'package:collab_tasks/features/calls/domain/models/call_status.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_connection_state.dart';
import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';
import 'package:collab_tasks/features/calls/domain/services/call_permissions_service.dart';
import 'package:collab_tasks/features/calls/domain/services/rtc_service.dart';
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
import 'package:collab_tasks/features/calls/ui/blocs/calls_state.dart';
import 'package:collab_tasks/features/calls/ui/screens/group_call_screen.dart';
import 'package:collab_tasks/features/calls/ui/screens/video_call_screen.dart';
import 'package:collab_tasks/features/calls/ui/widgets/rtc_video_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestCallsBloc extends CallsBloc {
  TestCallsBloc({
    required super.startCallUseCase,
    required super.acceptCallUseCase,
    required super.rejectCallUseCase,
    required super.endCallUseCase,
    required super.cancelCallUseCase,
    required super.leaveCallUseCase,
    required super.inviteParticipantUseCase,
    required super.requestCallPermissionsUseCase,
    required super.getCallSessionUseCase,
    required super.watchActiveCallUseCase,
    required super.joinRtcSessionUseCase,
    required super.leaveRtcSessionUseCase,
    required super.toggleMicrophoneUseCase,
    required super.toggleCameraUseCase,
    required super.switchCameraUseCase,
    required super.watchRtcConnectionStateUseCase,
    required super.watchRtcParticipantMediaStatesUseCase,
  });

  void emitState(CallsState state) => emit(state);
}

void main() {
  late InMemoryCallRepository callRepository;
  late FakeRtcService fakeRtcService;
  late FakeCallPermissionsService fakePermissionsService;
  late TestCallsBloc callsBloc;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    getIt.reset();

    callRepository = InMemoryCallRepository();
    fakeRtcService = FakeRtcService();
    fakePermissionsService = FakeCallPermissionsService();

    getIt
      ..registerLazySingleton<CallRepository>(() => callRepository)
      ..registerLazySingleton<CallPermissionsService>(
        () => fakePermissionsService,
      )
      ..registerLazySingleton<RtcService>(() => fakeRtcService)
      ..registerLazySingleton<RtcVideoViewFactory>(
        () => const FakeVideoViewFactory(),
      )
      ..registerLazySingleton(() => StartCallUseCase(getIt<CallRepository>()))
      ..registerLazySingleton(() => AcceptCallUseCase(getIt<CallRepository>()))
      ..registerLazySingleton(() => RejectCallUseCase(getIt<CallRepository>()))
      ..registerLazySingleton(() => EndCallUseCase(getIt<CallRepository>()))
      ..registerLazySingleton(() => CancelCallUseCase(getIt<CallRepository>()))
      ..registerLazySingleton(() => LeaveCallUseCase(getIt<CallRepository>()))
      ..registerLazySingleton(
        () => InviteParticipantUseCase(getIt<CallRepository>()),
      )
      ..registerLazySingleton(
        () => RequestCallPermissionsUseCase(getIt<CallPermissionsService>()),
      )
      ..registerLazySingleton(
        () => GetCallSessionUseCase(getIt<CallRepository>()),
      )
      ..registerLazySingleton(
        () => WatchActiveCallUseCase(getIt<CallRepository>()),
      )
      ..registerLazySingleton(() => JoinRtcSessionUseCase(getIt<RtcService>()))
      ..registerLazySingleton(() => LeaveRtcSessionUseCase(getIt<RtcService>()))
      ..registerLazySingleton(
        () => ToggleMicrophoneUseCase(getIt<RtcService>()),
      )
      ..registerLazySingleton(() => ToggleCameraUseCase(getIt<RtcService>()))
      ..registerLazySingleton(() => SwitchCameraUseCase(getIt<RtcService>()))
      ..registerLazySingleton(
        () => WatchRtcConnectionStateUseCase(getIt<RtcService>()),
      )
      ..registerLazySingleton(
        () => WatchRtcParticipantMediaStatesUseCase(getIt<RtcService>()),
      );

    callsBloc = TestCallsBloc(
      startCallUseCase: getIt(),
      acceptCallUseCase: getIt(),
      rejectCallUseCase: getIt(),
      endCallUseCase: getIt(),
      cancelCallUseCase: getIt(),
      leaveCallUseCase: getIt(),
      inviteParticipantUseCase: getIt(),
      requestCallPermissionsUseCase: getIt(),
      getCallSessionUseCase: getIt(),
      watchActiveCallUseCase: getIt(),
      joinRtcSessionUseCase: getIt(),
      leaveRtcSessionUseCase: getIt(),
      toggleMicrophoneUseCase: getIt(),
      toggleCameraUseCase: getIt(),
      switchCameraUseCase: getIt(),
      watchRtcConnectionStateUseCase: getIt(),
      watchRtcParticipantMediaStatesUseCase: getIt(),
    );
  });

  tearDown(() async {
    await callsBloc.close();
    callRepository.dispose();
    await fakeRtcService.dispose();
    await getIt.reset();
  });

  testWidgets('VideoCallScreen renders local pip and controls', (tester) async {
    final activeCall = Call(
      id: 'call-video-1',
      callerId: 'user-caller',
      callerName: 'Alice',
      calleeIds: const ['user-me'],
      type: CallType.video,
      status: CallStatus.active,
      createdAt: DateTime.now(),
    );

    // Use isCameraEnabled: false so the local PiP renders a placeholder
    // instead of RtcVideoView — avoids getIt lazy-singleton rebuild issues
    // across the FakeAsync/runAsync zone boundary.
    callsBloc.emitState(
      CallsState(
        status: CallsStatus.active,
        currentUserId: 'user-me',
        activeCall: activeCall,
        rtcConnectionState: RtcConnectionState.connected,
        isCameraEnabled: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<CallsBloc>.value(
          value: callsBloc,
          child: const VideoCallScreen(
            callId: 'call-video-1',
            opponentName: 'Alice',
            opponentId: 'user-caller',
          ),
        ),
      ),
    );

    // Initial render — camera off so tooltip reads 'Enable Camera'
    expect(find.text('Alice'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byTooltip('Mute'), findsOneWidget);
    expect(find.byTooltip('Enable Camera'), findsOneWidget);
    expect(find.byTooltip('Switch Camera'), findsOneWidget);

    // Tap mute toggle — runAsync avoids FakeAsync deadlock on bloc.stream.first
    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('Mute'));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(callsBloc.state.isMicrophoneMuted, isTrue);
  });

  testWidgets('GroupCallScreen renders participants and controls', (tester) async {
    final activeCall = Call(
      id: 'group-1',
      callerId: 'user-host',
      callerName: 'Team Standup',
      calleeIds: const ['user-1', 'user-2'],
      type: CallType.video,
      status: CallStatus.active,
      isGroup: true,
      participants: [
        CallParticipant(
          userId: 'user-host',
          displayName: 'Host User',
          role: CallParticipantRole.host,
          status: CallParticipantStatus.connected,
          joinedAt: DateTime.now(),
        ),
        const CallParticipant(
          userId: 'user-1',
          displayName: 'Bob',
          status: CallParticipantStatus.connected,
        ),
      ],
      createdAt: DateTime.now(),
    );

    callsBloc.emitState(
      CallsState(
        status: CallsStatus.active,
        currentUserId: 'user-me',
        activeCall: activeCall,
        rtcConnectionState: RtcConnectionState.connected,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<CallsBloc>.value(
          value: callsBloc,
          child: const GroupCallScreen(
            callId: 'group-1',
            groupName: 'Team Standup',
            callType: CallType.video,
          ),
        ),
      ),
    );

    expect(find.text('Team Standup'), findsOneWidget);
    expect(find.byIcon(Icons.person_add_alt_1), findsOneWidget);
    expect(find.text('Leave'), findsOneWidget);
  });
}
