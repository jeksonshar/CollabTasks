import 'dart:async';

import 'package:collab_tasks/features/calls/domain/models/call_data_entity.dart';
import 'package:collab_tasks/features/calls/domain/models/call_error_type.dart';
import 'package:collab_tasks/features/calls/domain/models/call_participant.dart';
import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
import 'package:collab_tasks/features/calls/domain/models/call_status.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_connection_state.dart';
import 'package:collab_tasks/features/calls/domain/services/call_kit_service.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/accept_call_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/accept_incoming_call_usecase.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/cancel_call_use_case.dart';
import 'package:collab_tasks/features/calls/domain/use_cases/cancel_incoming_call_usecase.dart';
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
import 'package:collab_tasks/features/calls/ui/blocs/call_kit_event_bridge.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_event.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_rtc_coordinator.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';

class CallsBloc extends Bloc<CallsEvent, CallsState> {
  final StartCallUseCase _startCallUseCase;
  final AcceptCallUseCase _acceptCallUseCase;
  final AcceptIncomingCallUseCase? _acceptIncomingCallUseCase;
  final DeclineIncomingCallUseCase? _declineIncomingCallUseCase;
  final CancelIncomingCallUseCase? _cancelIncomingCallUseCase;
  final CallKitService? _callKitService;
  final RejectCallUseCase _rejectCallUseCase;
  final EndCallUseCase _endCallUseCase;
  final CancelCallUseCase _cancelCallUseCase;
  final LeaveCallUseCase _leaveCallUseCase;
  final InviteParticipantUseCase _inviteParticipantUseCase;
  final RequestCallPermissionsUseCase _requestCallPermissionsUseCase;
  final GetCallSessionUseCase _getCallSessionUseCase;
  final WatchActiveCallUseCase _watchActiveCallUseCase;
  final WatchIncomingCallsUseCase _watchIncomingCallsUseCase;
  final StartIncomingAlertUseCase? _startIncomingAlertUseCase;
  final StartOutgoingAlertUseCase? _startOutgoingAlertUseCase;
  final StopCallAlertUseCase? _stopCallAlertUseCase;

  StreamSubscription? _activeCallSubscription;
  StreamSubscription? _incomingCallsSubscription;
  late final CallsRtcCoordinator _rtcCoordinator;
  CallKitEventBridge? _callKitEventBridge;
  Timer? _outgoingCallTimeoutTimer;
  final Set<String> _callKitDismissalsPending = {};
  final Set<String> _acceptedCallKitIds = {};
  final Set<String> _pendingCallKitAcceptIds = {};
  final Set<String> _resolvedIncomingCallIds = {};
  final Set<String> _callActionsInProgress = {};
  final Set<String> _terminalCallIds = {};
  final Map<String, ActiveCallUpdated> _deferredActiveCallUpdates = {};
  final Map<String, CallEvent> _deferredCallKitTerminalEvents = {};
  final Set<String> _deferredCancellationPushes = {};
  final Map<String, IncomingCallDetected> _incomingCallsDeferredDuringStart = {};
  final List<CallEvent> _pendingCallKitEvents = [];
  final List<CallDataEntity> _pendingAcceptedCallKitCalls = [];
  final List<CallDataEntity> _pendingDeclinedCallKitCalls = [];
  int _terminalEventSequence = 0;
  int _activeCallWatchSequence = 0;
  int _activeCallWatchGeneration = 0;
  bool _startCallInProgress = false;

  static const Duration _outgoingCallTimeoutDuration = Duration(seconds: 45);

  CallsBloc({
    required StartCallUseCase startCallUseCase,
    required AcceptCallUseCase acceptCallUseCase,
    AcceptIncomingCallUseCase? acceptIncomingCallUseCase,
    DeclineIncomingCallUseCase? declineIncomingCallUseCase,
    CancelIncomingCallUseCase? cancelIncomingCallUseCase,
    CallKitService? callKitService,
    Stream<CallEvent?>? callKitEvents,
    required RejectCallUseCase rejectCallUseCase,
    required EndCallUseCase endCallUseCase,
    required CancelCallUseCase cancelCallUseCase,
    required LeaveCallUseCase leaveCallUseCase,
    required InviteParticipantUseCase inviteParticipantUseCase,
    required RequestCallPermissionsUseCase requestCallPermissionsUseCase,
    required GetCallSessionUseCase getCallSessionUseCase,
    required WatchActiveCallUseCase watchActiveCallUseCase,
    required WatchIncomingCallsUseCase watchIncomingCallsUseCase,
    required JoinRtcSessionUseCase joinRtcSessionUseCase,
    required LeaveRtcSessionUseCase leaveRtcSessionUseCase,
    required ToggleMicrophoneUseCase toggleMicrophoneUseCase,
    required ToggleCameraUseCase toggleCameraUseCase,
    required ToggleSpeakerUseCase toggleSpeakerUseCase,
    required SwitchCameraUseCase switchCameraUseCase,
    required WatchRtcConnectionStateUseCase watchRtcConnectionStateUseCase,
    required WatchRtcParticipantMediaStatesUseCase watchRtcParticipantMediaStatesUseCase,
    StartIncomingAlertUseCase? startIncomingAlertUseCase,
    StartOutgoingAlertUseCase? startOutgoingAlertUseCase,
    StopCallAlertUseCase? stopCallAlertUseCase,
  }) : _startCallUseCase = startCallUseCase,
       _acceptCallUseCase = acceptCallUseCase,
       _acceptIncomingCallUseCase = acceptIncomingCallUseCase,
       _declineIncomingCallUseCase = declineIncomingCallUseCase,
       _cancelIncomingCallUseCase = cancelIncomingCallUseCase,
       _callKitService = callKitService,
       _rejectCallUseCase = rejectCallUseCase,
       _endCallUseCase = endCallUseCase,
       _cancelCallUseCase = cancelCallUseCase,
       _leaveCallUseCase = leaveCallUseCase,
       _inviteParticipantUseCase = inviteParticipantUseCase,
       _requestCallPermissionsUseCase = requestCallPermissionsUseCase,
       _getCallSessionUseCase = getCallSessionUseCase,
       _watchActiveCallUseCase = watchActiveCallUseCase,
       _watchIncomingCallsUseCase = watchIncomingCallsUseCase,
       _startIncomingAlertUseCase = startIncomingAlertUseCase,
       _startOutgoingAlertUseCase = startOutgoingAlertUseCase,
       _stopCallAlertUseCase = stopCallAlertUseCase,
       super(const CallsState()) {
    _rtcCoordinator = CallsRtcCoordinator(
      joinRtcSession: joinRtcSessionUseCase,
      leaveRtcSession: leaveRtcSessionUseCase,
      toggleMicrophone: toggleMicrophoneUseCase,
      toggleCamera: toggleCameraUseCase,
      toggleSpeaker: toggleSpeakerUseCase,
      switchCamera: switchCameraUseCase,
      watchConnectionState: watchRtcConnectionStateUseCase,
      watchParticipantMediaStates: watchRtcParticipantMediaStatesUseCase,
      dispatch: add,
    );
    on<StartCallRequested>(_onStartCall);
    on<IncomingCallDetected>(_onIncomingCallDetected);
    on<IncomingCallDialogOpened>(_onIncomingCallDialogOpened);
    on<StopCallAlertRequested>(_onStopCallAlertRequested);
    on<ListenIncomingCallsStarted>(_onListenIncomingCallsStarted);
    on<StopListeningIncomingCalls>(_onStopListeningIncomingCalls);
    on<CallTimeoutOccurred>(_onCallTimeoutOccurred);
    on<AcceptCallRequested>(_onAcceptCall);
    on<RejectCallRequested>(_onRejectCall);
    on<EndCallRequested>(_onEndCall);
    on<CancelCallRequested>(_onCancelCall);
    on<LeaveCallRequested>(_onLeaveCall);
    on<InviteParticipantRequested>(_onInviteParticipant);
    on<AppLifecycleChanged>(_onAppLifecycleChanged);
    on<ToggleMicrophoneRequested>(_onToggleMicrophone);
    on<ToggleCameraRequested>(_onToggleCamera);
    on<ToggleSpeakerRequested>(_onToggleSpeaker);
    on<SwitchCameraRequested>(_onSwitchCamera);
    on<ActiveCallUpdated>(_onActiveCallUpdated);
    on<RtcConnectionStateChanged>(_onRtcConnectionStateChanged);
    on<ParticipantMediaStatesUpdated>(_onParticipantMediaStatesUpdated);
    on<CallKitEventReceived>(_onCallKitEventReceived);
    on<CallKitAccepted>(_onCallKitAccepted);
    on<CallKitDeclined>(_onCallKitDeclined);
    on<CallCancellationPushReceived>(_onCallCancellationPushReceived);
    _callKitEventBridge = CallKitEventBridge(
      events: callKitEvents,
      onEvent: (event) => add(CallKitEventReceived(event)),
    );
  }

  Future<void> _onStartCall(StartCallRequested event, Emitter<CallsState> emit) async {
    if (_startCallInProgress || state.status != CallsStatus.idle || _trackedCallId != null) {
      debugPrint('[CallsBloc] Ignoring duplicate start request while another call is active');
      return;
    }
    // Reserve synchronously before requesting permissions or performing any
    // other asynchronous work. Different event types are concurrent in Bloc.
    _startCallInProgress = true;
    debugPrint('[CallsBloc] _onStartCall: type=${event.type}, callee=${event.calleeIds}');
    try {
      final permissionsGranted = await _requestCallPermissionsUseCase(type: event.type);
      if (!permissionsGranted) {
        debugPrint('[CallsBloc] Permissions denied for call type: ${event.type}');
        await _finishCall(
          emit,
          currentUserId: event.callerId,
          errorType: event.type == CallType.video
              ? CallErrorType.permissionDeniedVideo
              : CallErrorType.permissionDeniedAudio,
        );
        return;
      }

      emit(
        state.copyWith(
          status: event.isGroup ? CallsStatus.active : CallsStatus.ringingOutgoing,
          currentUserId: () => event.callerId,
          isCameraEnabled: event.type == CallType.video,
          errorMessage: () => null,
          errorType: () => null,
        ),
      );
      if (!event.isGroup) {
        await _startOutgoingAlertSafely();
      }

      final call = await _startCallUseCase(
        callId: event.callId,
        callerId: event.callerId,
        callerName: event.callerName,
        callerAvatarUrl: event.callerAvatarUrl,
        calleeIds: event.calleeIds,
        type: event.type,
        isGroup: event.isGroup,
        groupId: event.groupId,
      );

      debugPrint('[CallsBloc] Call created: id=${call.id}, status=${call.status}');
      emit(state.copyWith(activeCall: () => call));

      if (event.isGroup) {
        final session = await _getCallSessionUseCase(callId: call.id, userId: event.callerId);
        emit(
          state.copyWith(
            status: CallsStatus.active,
            session: () => session,
            isCameraEnabled: event.type == CallType.video,
          ),
        );
        debugPrint(
          '[CallsBloc] Group call host joining RTC media session: roomId=${session.roomId}',
        );
        await _joinRtcSession(session);
        await _subscribeToActiveCall(call.id);
      } else {
        _startOutgoingCallTimeout();
        await _subscribeToActiveCall(call.id);
      }
    } catch (e, st) {
      debugPrint('[CallsBloc] Error starting call: $e\n$st');
      final callId = state.activeCall?.id;
      if (callId != null) {
        try {
          await _cancelCallUseCase(callId);
        } catch (_) {}
      }
      await _finishCall(
        emit,
        callId: callId,
        currentUserId: event.callerId,
        errorType: CallErrorType.unknown,
        errorMessage: e.toString(),
      );
    } finally {
      _startCallInProgress = false;
      _drainIncomingCallsDeferredDuringStart();
    }
  }

  Future<void> _onIncomingCallDetected(IncomingCallDetected event, Emitter<CallsState> emit) async {
    if (_startCallInProgress && state.status == CallsStatus.idle) {
      _incomingCallsDeferredDuringStart[event.call.id] = event;
      return;
    }
    // watchIncomingCalls already filters by the authenticated user's email/UID
    // aliases and the keyed participant record's ringing status.
    final isParticipantRinging = event.call.participants.any(
      (participant) => participant.status == CallParticipantStatus.ringing,
    );
    if (isParticipantRinging) {
      _resolvedIncomingCallIds.remove(event.call.id);
      _terminalCallIds.remove(event.call.id);
    }

    if (state.status != CallsStatus.idle ||
        _acceptedCallKitIds.contains(event.call.id) ||
        _resolvedIncomingCallIds.contains(event.call.id) ||
        _isCallKitAcceptPending(event.call.id)) {
      return;
    }

    emit(
      state.copyWith(
        status: CallsStatus.ringingIncoming,
        activeCall: () => event.call,
        errorMessage: () => null,
        errorType: () => null,
      ),
    );

    await _subscribeToActiveCall(event.call.id);
  }

  bool _isCallKitAcceptPending(String callId) {
    return _pendingCallKitAcceptIds.contains(callId) ||
        _acceptedCallKitIds.contains(callId) ||
        _pendingAcceptedCallKitCalls.any((call) => call.callId == callId) ||
        _pendingCallKitEvents.any(
          (event) => event is CallEventActionCallAccept && event.callKitParams.id == callId,
        );
  }

  Future<void> _onIncomingCallDialogOpened(
    IncomingCallDialogOpened event,
    Emitter<CallsState> emit,
  ) async {
    if (state.status != CallsStatus.ringingIncoming ||
        state.activeCall?.id != event.callId ||
        _acceptedCallKitIds.contains(event.callId)) {
      return;
    }
    await _startIncomingAlertSafely();
  }

  Future<void> _onStopCallAlertRequested(
    StopCallAlertRequested event,
    Emitter<CallsState> emit,
  ) async {
    await _stopCallAlertSafely();
  }

  Future<void> _onAcceptCall(AcceptCallRequested event, Emitter<CallsState> emit) async {
    if (_acceptedCallKitIds.contains(event.callId) || !_reserveCallAction(event.callId)) {
      return;
    }
    _acceptedCallKitIds.add(event.callId);
    _resolvedIncomingCallIds.add(event.callId);
    try {
      await _stopCallAlertSafely();
      final callType = state.activeCall?.type ?? CallType.audio;
      final permissionsGranted = await _requestCallPermissionsUseCase(type: callType);
      if (!permissionsGranted) {
        _acceptedCallKitIds.remove(event.callId);
        try {
          await _rejectCallUseCase(callId: event.callId, userId: event.userId);
        } catch (_) {}
        await _finishCall(
          emit,
          callId: event.callId,
          currentUserId: event.userId,
          errorType: callType == CallType.video
              ? CallErrorType.permissionDeniedVideo
              : CallErrorType.permissionDeniedAudio,
        );
        return;
      }

      emit(
        state.copyWith(
          currentUserId: () => event.userId,
          status: CallsStatus.active,
          isCameraEnabled: callType == CallType.video,
        ),
      );

      await _acceptCallUseCase(callId: event.callId, userId: event.userId);

      final session = await _getCallSessionUseCase(callId: event.callId, userId: event.userId);

      await _dismissCallKitCall(event.callId);
      final acceptedCall = state.activeCall;
      emit(
        CallAcceptedState(
          callData: CallDataEntity(
            callId: event.callId,
            displayName: acceptedCall?.callerName ?? 'Unknown caller',
            handle: acceptedCall?.callerId ?? '',
            agoraChannel: session.roomId,
            token: session.token,
            callerId: acceptedCall?.callerId ?? '',
            callerAvatarUrl: acceptedCall?.callerAvatarUrl,
            callType: callType,
            isGroup: acceptedCall?.isGroup ?? false,
          ),
          session: session,
          activeCall: acceptedCall,
          currentUserId: event.userId,
          isCameraEnabled: callType == CallType.video,
        ),
      );

      await _subscribeToActiveCall(event.callId);
      await _joinRtcSession(session);
    } catch (e) {
      _acceptedCallKitIds.remove(event.callId);
      try {
        await _rejectCallUseCase(callId: event.callId, userId: event.userId);
      } catch (_) {}
      await _finishCall(
        emit,
        callId: event.callId,
        currentUserId: event.userId,
        errorType: CallErrorType.unknown,
        errorMessage: e.toString(),
      );
    } finally {
      _releaseCallAction(event.callId);
    }
  }

  Future<void> _onRejectCall(RejectCallRequested event, Emitter<CallsState> emit) async {
    if (_resolvedIncomingCallIds.contains(event.callId) || !_reserveCallAction(event.callId)) {
      return;
    }
    _resolvedIncomingCallIds.add(event.callId);
    try {
      await _rejectCallUseCase(callId: event.callId, userId: event.userId);
    } catch (e) {
      // Ignored on reject
    } finally {
      try {
        await _finishCall(emit, callId: event.callId, currentUserId: event.userId);
      } finally {
        _releaseCallAction(event.callId);
      }
    }
  }

  Future<void> _onEndCall(EndCallRequested event, Emitter<CallsState> emit) async {
    final callId = event.callId ?? state.activeCall?.id;
    if (callId == null || !_reserveCallAction(callId)) return;
    emit(state.copyWith(status: CallsStatus.terminating));

    try {
      await _endCallUseCase(callId);
    } catch (e) {
      // Ignored on end
    } finally {
      try {
        await _dismissCallKitCall(callId);
        await _finishCall(emit, callId: callId);
      } finally {
        _releaseCallAction(callId);
      }
    }
  }

  Future<void> _onCancelCall(CancelCallRequested event, Emitter<CallsState> emit) async {
    final callId = event.callId ?? state.activeCall?.id;
    if (callId == null || !_reserveCallAction(callId)) return;
    emit(state.copyWith(status: CallsStatus.terminating));

    try {
      await _cancelCallUseCase(callId);
    } catch (_) {
      // Keep local teardown deterministic even when the remote update fails.
    } finally {
      try {
        await _dismissCallKitCall(callId);
        await _finishCall(emit, callId: callId);
      } finally {
        _releaseCallAction(callId);
      }
    }
  }

  Future<void> _onLeaveCall(LeaveCallRequested event, Emitter<CallsState> emit) async {
    final callId = state.activeCall?.id;
    final userId = state.currentUserId;
    if (callId == null || !_reserveCallAction(callId)) return;
    emit(state.copyWith(status: CallsStatus.terminating));

    if (userId != null) {
      try {
        await _leaveCallUseCase(callId: callId, userId: userId);
      } catch (error, stackTrace) {
        debugPrint(
          '[CallsBloc] Failed to persist participant leave for $callId: '
          '$error\n$stackTrace',
        );
      }
      await _dismissCallKitCall(callId);
      _resolvedIncomingCallIds.remove(callId);
      _acceptedCallKitIds.remove(callId);
      _pendingCallKitAcceptIds.remove(callId);
    }
    try {
      await _finishCall(emit, callId: callId);
    } finally {
      _releaseCallAction(callId);
    }
  }

  Future<void> _onInviteParticipant(
    InviteParticipantRequested event,
    Emitter<CallsState> emit,
  ) async {
    final callId = state.activeCall?.id;
    if (callId != null) {
      try {
        await _inviteParticipantUseCase(
          callId: callId,
          userId: event.userId,
          displayName: event.displayName,
          avatarUrl: event.avatarUrl,
        );
      } catch (e, st) {
        debugPrint('[CallsBloc] Failed to invite ${event.userId} to $callId: $e\n$st');
        emit(
          state.copyWith(
            status: state.status,
            errorType: () => CallErrorType.inviteFailed,
            errorMessage: () => e.toString(),
          ),
        );
      }
    }
  }

  Future<void> _onAppLifecycleChanged(AppLifecycleChanged event, Emitter<CallsState> emit) async {
    if (state.status != CallsStatus.active) return;

    switch (event.lifecycleState) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Disable the camera when backgrounded, but only if the user had not
        // already turned it off manually (avoid double-toggling Agora SDK).
        if (state.isCameraEnabled && state.activeCall?.type == CallType.video) {
          await _rtcCoordinator.toggleCamera(false);
          // Do NOT set isCameraManuallyDisabled here — this is a system pause,
          // not a user action. The flag remains as it was so resumed can restore
          // the camera if the user had not explicitly disabled it.
          emit(state.copyWith(isCameraEnabled: false));
        }
        break;
      case AppLifecycleState.resumed:
        // Restore the camera only if:
        //   1. it is currently off (was paused by the system), AND
        //   2. the user did NOT manually disable it before backgrounding.
        if (!state.isCameraEnabled &&
            !state.isCameraManuallyDisabled &&
            state.activeCall?.type == CallType.video) {
          await _rtcCoordinator.toggleCamera(true);
          emit(state.copyWith(isCameraEnabled: true));
        }
        break;
      case AppLifecycleState.detached:
        add(const EndCallRequested());
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _onToggleMicrophone(
    ToggleMicrophoneRequested event,
    Emitter<CallsState> emit,
  ) async {
    final newMuted = !state.isMicrophoneMuted;
    try {
      await _rtcCoordinator.toggleMicrophone(newMuted);
      emit(state.copyWith(isMicrophoneMuted: newMuted));
    } catch (e, st) {
      debugPrint('[CallsBloc] Failed to toggle microphone: $e\n$st');
      emit(
        state.copyWith(
          errorType: () => CallErrorType.rtcConnectionFailed,
          errorMessage: () => e.toString(),
        ),
      );
    }
  }

  Future<void> _onToggleCamera(ToggleCameraRequested event, Emitter<CallsState> emit) async {
    final newEnabled = !state.isCameraEnabled;
    try {
      await _rtcCoordinator.toggleCamera(newEnabled);
      emit(
        state.copyWith(
          isCameraEnabled: newEnabled,
          // Track that the user explicitly disabled/enabled the camera so
          // the lifecycle handler does not restore it against the user's intent.
          isCameraManuallyDisabled: !newEnabled,
        ),
      );
    } catch (e, st) {
      debugPrint('[CallsBloc] Failed to toggle camera: $e\n$st');
      emit(
        state.copyWith(
          errorType: () => CallErrorType.rtcConnectionFailed,
          errorMessage: () => e.toString(),
        ),
      );
    }
  }

  Future<void> _onToggleSpeaker(ToggleSpeakerRequested event, Emitter<CallsState> emit) async {
    final newEnabled = !state.isSpeakerEnabled;
    try {
      await _rtcCoordinator.toggleSpeaker(newEnabled);
      emit(state.copyWith(isSpeakerEnabled: newEnabled));
    } catch (e, st) {
      debugPrint('[CallsBloc] Failed to toggle speaker: $e\n$st');
      emit(
        state.copyWith(
          errorType: () => CallErrorType.rtcConnectionFailed,
          errorMessage: () => e.toString(),
        ),
      );
    }
  }

  Future<void> _onSwitchCamera(SwitchCameraRequested event, Emitter<CallsState> emit) async {
    try {
      await _rtcCoordinator.switchCamera();
    } catch (e, st) {
      debugPrint('[CallsBloc] Failed to switch camera: $e\n$st');
      emit(
        state.copyWith(
          errorType: () => CallErrorType.rtcConnectionFailed,
          errorMessage: () => e.toString(),
        ),
      );
    }
  }

  void _onListenIncomingCallsStarted(ListenIncomingCallsStarted event, Emitter<CallsState> emit) {
    debugPrint('[CallsBloc] Starting incoming calls listener for: ${event.userId}');
    _incomingCallsSubscription?.cancel();
    emit(state.copyWith(currentUserId: () => event.userId));
    if (_pendingCallKitEvents.isNotEmpty) {
      final pendingEvents = List<CallEvent>.of(_pendingCallKitEvents);
      _pendingCallKitEvents.clear();
      for (final pendingEvent in pendingEvents) {
        if (pendingEvent is CallEventActionCallAccept) {
          _pendingCallKitAcceptIds.add(pendingEvent.callKitParams.id);
        }
        add(CallKitEventReceived(pendingEvent));
      }
    }
    if (_pendingAcceptedCallKitCalls.isNotEmpty) {
      final pendingCalls = List<CallDataEntity>.of(_pendingAcceptedCallKitCalls);
      _pendingAcceptedCallKitCalls.clear();
      for (final callData in pendingCalls) {
        _pendingCallKitAcceptIds.add(callData.callId);
        add(CallKitAccepted(callData));
      }
    }
    if (_pendingDeclinedCallKitCalls.isNotEmpty) {
      final pendingCalls = List<CallDataEntity>.of(_pendingDeclinedCallKitCalls);
      _pendingDeclinedCallKitCalls.clear();
      for (final callData in pendingCalls) {
        add(CallKitDeclined(callData));
      }
    }
    final normalizedUserId = event.userId.trim().toLowerCase();

    _incomingCallsSubscription = _watchIncomingCallsUseCase(normalizedUserId).listen(
      (calls) {
        debugPrint('[CallsBloc] Received incoming calls update: ${calls.length} call(s)');
        for (final call in calls) {
          final isCallRingingOrActive =
              call.status == CallStatus.ringing || call.status == CallStatus.active;
          if (isCallRingingOrActive &&
              call.participants.any(
                (participant) => participant.status == CallParticipantStatus.ringing,
              )) {
            debugPrint('[CallsBloc] Incoming call detected from ${call.callerName} (${call.id})');
            add(IncomingCallDetected(call));
            break;
          }
        }
      },
      onError: (e) {
        debugPrint('[CallsBloc] Error in incoming calls listener: $e');
      },
    );
  }

  Future<void> _onCallKitEventReceived(CallKitEventReceived event, Emitter<CallsState> emit) async {
    final nativeEvent = event.event;
    final callData = switch (nativeEvent) {
      CallEventActionCallAccept() => _callDataFromParams(nativeEvent.callKitParams),
      CallEventActionCallDecline() => _callDataFromParams(nativeEvent.callKitParams),
      _ => null,
    };
    if (nativeEvent is CallEventActionCallAccept) {
      if (_acceptedCallKitIds.contains(nativeEvent.callKitParams.id)) return;
      _terminalCallIds.remove(nativeEvent.callKitParams.id);
      _pendingCallKitAcceptIds.add(nativeEvent.callKitParams.id);
    }
    final requiresUser =
        nativeEvent is CallEventActionCallAccept || nativeEvent is CallEventActionCallDecline;
    final recipientId = nativeEvent is CallEventActionCallDecline
        ? _resolveCallRecipientId(callData)
        : state.currentUserId?.trim() ?? '';
    if (requiresUser && recipientId.isEmpty) {
      if (!_pendingCallKitEvents.any(
        (pending) => _isDuplicateCallKitAction(pending, nativeEvent),
      )) {
        _pendingCallKitEvents.add(nativeEvent);
      }
      debugPrint('[CallsBloc] Deferring CallKit action until recipient identity is ready');
      return;
    }
    if (nativeEvent is CallEventActionCallAccept) {
      await _acceptCallKitData(callData!, emit);
      return;
    }

    if (nativeEvent is CallEventActionCallDecline) {
      await _declineCallKitData(callData!, emit, userId: recipientId);
      return;
    }

    if (nativeEvent is CallEventActionCallTimeout) {
      await _endCallFromCallKit(nativeEvent.id, emit, nativeEvent: nativeEvent);
      return;
    }

    if (nativeEvent is CallEventActionCallEnded) {
      await _endCallFromCallKit(nativeEvent.callKitParams.id, emit, nativeEvent: nativeEvent);
    }
  }

  Future<void> _onCallKitAccepted(CallKitAccepted event, Emitter<CallsState> emit) async {
    if (_acceptedCallKitIds.contains(event.callData.callId)) return;
    _terminalCallIds.remove(event.callData.callId);
    _pendingCallKitAcceptIds.add(event.callData.callId);
    if (state.currentUserId == null || state.currentUserId!.isEmpty) {
      if (!_pendingAcceptedCallKitCalls.any((call) => call.callId == event.callData.callId)) {
        _pendingAcceptedCallKitCalls.add(event.callData);
      }
      debugPrint('[CallsBloc] Deferring restored CallKit accept until recipient identity is ready');
      return;
    }
    await _acceptCallKitData(event.callData, emit);
  }

  Future<void> _onCallKitDeclined(CallKitDeclined event, Emitter<CallsState> emit) async {
    final callData = event.callData;
    final userId = state.currentUserId?.trim().isNotEmpty == true
        ? state.currentUserId!.trim()
        : callData.calleeId.trim();
    if (userId.isEmpty) {
      if (!_pendingDeclinedCallKitCalls.any((call) => call.callId == callData.callId)) {
        _pendingDeclinedCallKitCalls.add(callData);
      }
      debugPrint(
        '[CallsBloc] Deferring restored CallKit decline until recipient identity is ready',
      );
      return;
    }
    await _declineCallKitData(callData, emit, userId: userId);
  }

  Future<void> _declineCallKitData(
    CallDataEntity callData,
    Emitter<CallsState> emit, {
    String? userId,
  }) async {
    final callId = callData.callId;
    if (callId.isEmpty ||
        _resolvedIncomingCallIds.contains(callId) ||
        !_reserveCallAction(callId)) {
      return;
    }
    _resolvedIncomingCallIds.add(callId);
    final recipientId = userId ?? state.currentUserId ?? callData.calleeId;
    try {
      if (recipientId.trim().isEmpty || _declineIncomingCallUseCase == null) {
        await _finishCall(
          emit,
          callId: callId,
          currentUserId: recipientId,
          errorType: CallErrorType.userUnavailable,
        );
        return;
      }
      _callKitDismissalsPending.add(callId);
      await _declineIncomingCallUseCase.call(callId: callId, userId: recipientId);
      await _finishCall(emit, callId: callId, currentUserId: recipientId);
    } catch (error, stackTrace) {
      _callKitDismissalsPending.remove(callId);
      debugPrint('[CallsBloc] Failed to decline CallKit call: $error\n$stackTrace');
      await _finishCall(
        emit,
        callId: callId,
        currentUserId: recipientId,
        errorType: CallErrorType.unknown,
        errorMessage: error.toString(),
      );
    } finally {
      _releaseCallAction(callId);
    }
  }

  Future<void> _onCallCancellationPushReceived(
    CallCancellationPushReceived event,
    Emitter<CallsState> emit,
  ) async {
    if (event.callId.isEmpty || !_reserveCallAction(event.callId)) {
      if (_callActionsInProgress.contains(event.callId)) {
        _deferredCancellationPushes.add(event.callId);
      }
      return;
    }
    _resolvedIncomingCallIds.add(event.callId);
    _pendingCallKitAcceptIds.remove(event.callId);
    _callKitDismissalsPending.add(event.callId);
    try {
      try {
        await _cancelIncomingCallUseCase?.call(event.callId);
      } catch (error) {
        debugPrint('[CallsBloc] Failed to dismiss remotely cancelled call: $error');
      }

      final currentState = state;
      var activeCallId = currentState.activeCall?.id;
      activeCallId = currentState.acceptedCallData?.callId ?? activeCallId;
      if (activeCallId == event.callId ||
          (state.status == CallsStatus.ringingIncoming && state.activeCall?.id == event.callId)) {
        await _finishCall(emit, callId: event.callId);
      }
    } finally {
      _releaseCallAction(event.callId);
    }
  }

  Future<void> _acceptCallKitData(CallDataEntity callData, Emitter<CallsState> emit) async {
    final trackedCallId = _trackedCallId;
    final competingAcceptId = {
      ..._acceptedCallKitIds,
      ..._pendingCallKitAcceptIds,
    }.firstWhere((pendingCallId) => pendingCallId != callData.callId, orElse: () => '');
    final callIdBeingHandled =
        trackedCallId ?? (competingAcceptId.isEmpty ? null : competingAcceptId);
    if (callIdBeingHandled != null && callIdBeingHandled != callData.callId) {
      debugPrint(
        '[CallsBloc] Ignoring stale CallKit accept for ${callData.callId}; '
        'currently handling $callIdBeingHandled',
      );
      _pendingCallKitAcceptIds.remove(callData.callId);
      await _dismissCallKitCall(callData.callId);
      return;
    }
    if (!_reserveCallAction(callData.callId)) return;
    if (!_acceptedCallKitIds.add(callData.callId)) {
      _releaseCallAction(callData.callId);
      return;
    }
    _pendingCallKitAcceptIds.remove(callData.callId);
    _resolvedIncomingCallIds.add(callData.callId);
    final userId = state.currentUserId;
    final useCase = _acceptIncomingCallUseCase;
    try {
      await _stopCallAlertSafely();
      if (useCase == null || userId == null || userId.isEmpty) {
        _acceptedCallKitIds.remove(callData.callId);
        await _finishCall(
          emit,
          callId: callData.callId,
          currentUserId: userId ?? callData.calleeId,
          errorType: CallErrorType.userUnavailable,
        );
        return;
      }
      final granted = await _requestCallPermissionsUseCase(type: callData.callType);
      if (!granted) {
        _callKitDismissalsPending.add(callData.callId);
        await _declineIncomingCallUseCase?.call(callId: callData.callId, userId: userId);
        await _finishCall(
          emit,
          callId: callData.callId,
          currentUserId: userId,
          errorType: callData.callType == CallType.video
              ? CallErrorType.permissionDeniedVideo
              : CallErrorType.permissionDeniedAudio,
        );
        return;
      }
      _callKitDismissalsPending.add(callData.callId);
      // Native CallKit acceptance does not pass through IncomingCallDetected,
      // so establish the Firestore watcher here as well. It must stay active
      // to observe the caller ending the accepted call.
      await _subscribeToActiveCall(callData.callId);
      final session = await useCase(callData: callData, userId: userId);
      if (session == null) {
        debugPrint('[CallsBloc] Ignoring stale CallKit accept for ${callData.callId}');
        await _finishCall(emit, callId: callData.callId, currentUserId: userId);
        return;
      }
      final resolvedCallData = callData.copyWith(
        callType: session.extra['mediaType'] == CallType.video.name
            ? CallType.video
            : CallType.audio,
        isGroup: session.extra['isGroup'] is bool
            ? session.extra['isGroup'] as bool
            : callData.isGroup,
        displayName:
            session.extra['callName'] is String && (session.extra['callName'] as String).isNotEmpty
            ? session.extra['callName'] as String
            : callData.displayName,
      );
      emit(
        CallAcceptedState(
          callData: resolvedCallData,
          session: session,
          activeCall: state.activeCall,
          currentUserId: userId,
          isCameraEnabled: callData.callType == CallType.video,
        ),
      );
      await _joinRtcSession(session);
    } catch (error, stackTrace) {
      _acceptedCallKitIds.remove(callData.callId);
      _callKitDismissalsPending.remove(callData.callId);
      debugPrint('[CallsBloc] Failed to accept CallKit call: $error\n$stackTrace');
      await _finishCall(
        emit,
        callId: callData.callId,
        currentUserId: userId,
        errorType: CallErrorType.unknown,
        errorMessage: error.toString(),
      );
    } finally {
      _releaseCallAction(callData.callId);
    }
  }

  Future<void> _dismissCallKitCall(String callId) async {
    try {
      _callKitDismissalsPending.add(callId);
      await _callKitService?.endCall(callId);
    } catch (error) {
      debugPrint('[CallsBloc] Failed to end native call: $error');
    }
  }

  CallDataEntity _callDataFromParams(CallKitParams params) {
    return CallDataEntity.fromMap({
      ...?params.extra,
      'callId': params.id,
      'displayName': params.nameCaller,
      'handle': params.handle,
      'callType': params.type?.toString() ?? '0',
    });
  }

  String _resolveCallRecipientId(CallDataEntity? callData) {
    final currentUserId = state.currentUserId?.trim() ?? '';
    if (currentUserId.isNotEmpty) return currentUserId;

    final payloadRecipientId = callData?.calleeId.trim() ?? '';
    if (payloadRecipientId.isNotEmpty) {
      debugPrint('[CallsBloc] Using calleeId from CallKit payload as recipient identity');
      return payloadRecipientId;
    }
    return '';
  }

  Future<void> _endCallFromCallKit(
    String callId,
    Emitter<CallsState> emit, {
    CallEvent? nativeEvent,
  }) async {
    if (_callKitDismissalsPending.remove(callId)) return;
    if (!_reserveCallAction(callId)) {
      if (_callActionsInProgress.contains(callId)) {
        // A remote/native terminal signal must not be lost while Accept is in
        // flight. Re-dispatch it after the current action releases the gate.
        // If the current action itself terminates the call, the terminal ID
        // check will make this replay a no-op.
        if (nativeEvent != null) {
          _deferredCallKitTerminalEvents[callId] = nativeEvent;
        }
      }
      return;
    }
    _resolvedIncomingCallIds.add(callId);
    _acceptedCallKitIds.remove(callId);
    _pendingCallKitAcceptIds.remove(callId);
    _callKitDismissalsPending.add(callId);
    try {
      await _cancelIncomingCallUseCase?.call(callId);
    } catch (error) {
      debugPrint('[CallsBloc] Failed to clear CallKit call: $error');
    } finally {
      try {
        await _finishCall(emit, callId: callId);
      } finally {
        _releaseCallAction(callId);
      }
    }
  }

  void _onStopListeningIncomingCalls(StopListeningIncomingCalls event, Emitter<CallsState> emit) {
    debugPrint('[CallsBloc] Stopping incoming calls listener');
    _incomingCallsSubscription?.cancel();
    _incomingCallsSubscription = null;
    emit(const CallsState());
  }

  Future<void> _onCallTimeoutOccurred(CallTimeoutOccurred event, Emitter<CallsState> emit) async {
    if (state.status != CallsStatus.ringingOutgoing) return;
    debugPrint('[CallsBloc] Outgoing call timed out (no answer)');

    final callId = state.activeCall?.id;
    if (callId == null || !_reserveCallAction(callId)) return;
    try {
      try {
        await _cancelCallUseCase(callId);
      } catch (e) {
        debugPrint('[CallsBloc] Error cancelling timed-out call: $e');
      }
      await _finishCall(emit, callId: callId, errorType: CallErrorType.callTimeout);
    } finally {
      _releaseCallAction(callId);
    }
  }

  void _startOutgoingCallTimeout() {
    _stopOutgoingCallTimeout();
    debugPrint('[CallsBloc] Starting 45s outgoing call timeout timer');
    _outgoingCallTimeoutTimer = Timer(_outgoingCallTimeoutDuration, () {
      add(const CallTimeoutOccurred());
    });
  }

  void _stopOutgoingCallTimeout() {
    if (_outgoingCallTimeoutTimer != null) {
      debugPrint('[CallsBloc] Stopping outgoing call timeout timer');
      _outgoingCallTimeoutTimer?.cancel();
      _outgoingCallTimeoutTimer = null;
    }
  }

  Future<void> _onActiveCallUpdated(ActiveCallUpdated event, Emitter<CallsState> emit) async {
    final call = event.call;
    final watchedCallId = event.watchedCallId ?? call?.id;
    if (event.watchGeneration != null && event.watchGeneration != _activeCallWatchGeneration) {
      debugPrint(
        '[CallsBloc] Ignoring active-call update from stale watch generation '
        '${event.watchGeneration}',
      );
      return;
    }
    final trackedCallId = _trackedCallId;
    if (watchedCallId != null && trackedCallId != null && watchedCallId != trackedCallId) {
      debugPrint(
        '[CallsBloc] Ignoring stale active-call update for $watchedCallId; '
        'currently handling $trackedCallId',
      );
      return;
    }
    if (call != null && watchedCallId != null && call.id != watchedCallId) {
      debugPrint('[CallsBloc] Ignoring mismatched active-call snapshot for $watchedCallId');
      return;
    }
    final isTerminalUpdate =
        call == null ||
        call.status == CallStatus.rejected ||
        call.status == CallStatus.ended ||
        call.status == CallStatus.cancelled;
    if (watchedCallId != null &&
        isTerminalUpdate &&
        _callActionsInProgress.contains(watchedCallId)) {
      _deferredActiveCallUpdates[watchedCallId] = event;
      return;
    }
    if (watchedCallId != null &&
        _terminalCallIds.contains(watchedCallId) &&
        state.status == CallsStatus.idle) {
      return;
    }
    if (state.status == CallsStatus.idle && call == null) {
      debugPrint('[CallsBloc] Ignoring stale active-call update while idle');
      return;
    }
    if (state.status == CallsStatus.idle &&
        state.activeCall == null &&
        state.session == null &&
        call?.id == state.terminalCallId) {
      debugPrint('[CallsBloc] Ignoring terminal update for ${call?.id} while idle');
      return;
    }
    if (call == null) {
      debugPrint('[CallsBloc] Active call updated to null -> cleaning up');
      await _finishCall(emit, callId: state.activeCall?.id);
      return;
    }

    debugPrint('[CallsBloc] Active call updated: id=${call.id}, status=${call.status}');
    emit(state.copyWith(activeCall: () => call));

    // Caller scenario: callee accepted -> transition from ringing to active & join RTC
    if (state.status == CallsStatus.ringingOutgoing &&
        state.activeCall?.id == call.id &&
        !_acceptedCallKitIds.contains(call.id) &&
        call.status == CallStatus.active) {
      _stopOutgoingCallTimeout();
      await _stopCallAlertSafely();
      final userId = state.currentUserId ?? call.callerId;
      try {
        debugPrint('[CallsBloc] Call became active! Obtaining RTC session...');
        final session = await _getCallSessionUseCase(callId: call.id, userId: userId);

        // ── Guard ────────────────────────────────────────────────────────────
        // While the token HTTP request was in-flight, the remote party may have
        // ended/cancelled the call. Another ActiveCallUpdated(ended) would have
        // run _cleanup() and emitted idle already. Proceeding to joinSession
        // here would open an RTC session for a dead call and leave the mic
        // active with no way to release it.
        if (isClosed || state.status == CallsStatus.idle) {
          debugPrint('[CallsBloc] Call ended while fetching RTC token — aborting join');
          return;
        }
        // ─────────────────────────────────────────────────────────────────────

        emit(
          state.copyWith(
            status: CallsStatus.active,
            session: () => session,
            isCameraEnabled: call.type == CallType.video,
          ),
        );
        debugPrint('[CallsBloc] Joining RTC media session: roomId=${session.roomId}');
        await _joinRtcSession(session);
      } catch (e, st) {
        debugPrint('[CallsBloc] Error joining RTC session: $e\n$st');
        await _finishCall(
          emit,
          callId: call.id,
          errorType: CallErrorType.unknown,
          errorMessage: e.toString(),
        );
      }
    } else if (call.status == CallStatus.rejected) {
      debugPrint('[CallsBloc] Call was rejected by recipient');
      await _finishCall(emit, callId: call.id);
    } else if (call.status == CallStatus.ended || call.status == CallStatus.cancelled) {
      debugPrint('[CallsBloc] Call ended or cancelled');
      await _finishCall(emit, callId: call.id);
    }
  }

  Future<void> _onRtcConnectionStateChanged(
    RtcConnectionStateChanged event,
    Emitter<CallsState> emit,
  ) async {
    debugPrint('[CallsBloc] RTC Connection state changed: ${event.state}');
    emit(state.copyWith(rtcConnectionState: event.state));

    if (event.state == RtcConnectionState.failed) {
      // Guard against double-fire: Agora can emit `failed` twice when
      // leaveSession() (called from onError) triggers onConnectionStateChanged.
      if (state.status == CallsStatus.idle) {
        debugPrint('[CallsBloc] RTC failed event ignored — already in ${state.status}');
        return;
      }
      debugPrint(
        '[CallsBloc] RTC connection failed, explicitly calling leaveSession to release microphone...',
      );
      try {
        await _rtcCoordinator.leaveSession();
      } catch (e) {
        debugPrint('[CallsBloc] Error leaving RTC session on failed state: $e');
      }
      await _finishCall(
        emit,
        callId: state.activeCall?.id,
        errorType: CallErrorType.rtcConnectionFailed,
      );
    }
  }

  void _onParticipantMediaStatesUpdated(
    ParticipantMediaStatesUpdated event,
    Emitter<CallsState> emit,
  ) {
    emit(state.copyWith(participantMediaStates: event.mediaStates));
  }

  Future<void> _subscribeToActiveCall(String callId) async {
    debugPrint('[CallsBloc] Subscribing to active call: $callId');
    final watchGeneration = ++_activeCallWatchSequence;
    _activeCallWatchGeneration = watchGeneration;
    await _activeCallSubscription?.cancel();
    if (isClosed || _activeCallWatchGeneration != watchGeneration) return;
    _activeCallSubscription = _watchActiveCallUseCase(callId).listen(
      (call) =>
          add(ActiveCallUpdated(call, watchedCallId: callId, watchGeneration: watchGeneration)),
      onError: (err) {
        debugPrint('[CallsBloc] Error watching active call: $err');
        add(ActiveCallUpdated(null, watchedCallId: callId, watchGeneration: watchGeneration));
      },
    );
  }

  String? get _trackedCallId =>
      state.session?.callId ??
      state.acceptedCallData?.callId ??
      state.activeCall?.id ??
      (_acceptedCallKitIds.isEmpty ? null : _acceptedCallKitIds.first) ??
      (_pendingCallKitAcceptIds.isEmpty ? null : _pendingCallKitAcceptIds.first);

  bool _reserveCallAction(String callId) {
    if (callId.isEmpty ||
        _terminalCallIds.contains(callId) ||
        _callActionsInProgress.contains(callId)) {
      return false;
    }
    final trackedCallId = _trackedCallId;
    if (trackedCallId != null && trackedCallId != callId) return false;
    _callActionsInProgress.add(callId);
    return true;
  }

  void _releaseCallAction(String callId) {
    _callActionsInProgress.remove(callId);
    if (_terminalCallIds.contains(callId)) {
      _deferredActiveCallUpdates.remove(callId);
      _deferredCallKitTerminalEvents.remove(callId);
      _deferredCancellationPushes.remove(callId);
      return;
    }
    final activeUpdate = _deferredActiveCallUpdates.remove(callId);
    if (activeUpdate != null && !isClosed) add(activeUpdate);
    final callKitEvent = _deferredCallKitTerminalEvents.remove(callId);
    if (callKitEvent != null && !isClosed) {
      add(CallKitEventReceived(callKitEvent));
    }
    if (_deferredCancellationPushes.remove(callId) && !isClosed) {
      add(CallCancellationPushReceived(callId));
    }
  }

  bool _isDuplicateCallKitAction(CallEvent first, CallEvent second) {
    if (first is CallEventActionCallAccept && second is CallEventActionCallAccept) {
      return first.callKitParams.id == second.callKitParams.id;
    }
    if (first is CallEventActionCallDecline && second is CallEventActionCallDecline) {
      return first.callKitParams.id == second.callKitParams.id;
    }
    return false;
  }

  void _drainIncomingCallsDeferredDuringStart() {
    if (_startCallInProgress || state.status != CallsStatus.idle || isClosed) {
      return;
    }
    final pending = List<IncomingCallDetected>.of(_incomingCallsDeferredDuringStart.values);
    _incomingCallsDeferredDuringStart.clear();
    for (final event in pending) {
      add(event);
    }
  }

  Future<void> _joinRtcSession(CallSession session) => _rtcCoordinator.joinSession(
    session,
    isTerminal: state.status == CallsStatus.idle && state.terminalCallId == session.callId,
  );

  Future<void> _finishCall(
    Emitter<CallsState> emit, {
    String? callId,
    String? currentUserId,
    CallErrorType? errorType,
    String? errorMessage,
  }) async {
    final trackedCallId = _trackedCallId;
    if (callId != null && trackedCallId != null && callId != trackedCallId) {
      debugPrint(
        '[CallsBloc] Ignoring terminal event for stale call $callId; '
        'currently handling $trackedCallId',
      );
      _acceptedCallKitIds.remove(callId);
      _pendingCallKitAcceptIds.remove(callId);
      _rtcCoordinator.forgetCall(callId);
      await _dismissCallKitCall(callId);
      return;
    }
    if (callId != null && !_terminalCallIds.add(callId)) {
      debugPrint('[CallsBloc] Duplicate terminal transition ignored for $callId');
      return;
    }
    final preservedUserId = currentUserId ?? state.currentUserId;
    await _cleanup();
    if (callId != null) {
      _acceptedCallKitIds.remove(callId);
      _pendingCallKitAcceptIds.remove(callId);
      _rtcCoordinator.forgetCall(callId);
    }
    emit(
      CallEndedState(
        callId: callId,
        currentUserId: preservedUserId,
        errorType: errorType,
        errorMessage: errorMessage,
        terminalEventId: ++_terminalEventSequence,
        terminalCallId: callId,
      ),
    );
    _drainIncomingCallsDeferredDuringStart();
  }

  Future<void> _cleanup() async {
    _stopOutgoingCallTimeout();
    await _stopCallAlertSafely();

    _activeCallWatchGeneration = ++_activeCallWatchSequence;
    await _activeCallSubscription?.cancel();
    _activeCallSubscription = null;

    await _rtcCoordinator.cancelSubscriptions();

    try {
      await _rtcCoordinator.leaveSession();
    } catch (_) {}
  }

  Future<void> _startIncomingAlertSafely() async {
    try {
      await _startIncomingAlertUseCase?.call();
    } catch (e) {
      debugPrint('[CallsBloc] Failed to start incoming call alert: $e');
    }
  }

  Future<void> _startOutgoingAlertSafely() async {
    try {
      await _startOutgoingAlertUseCase?.call();
    } catch (e) {
      debugPrint('[CallsBloc] Failed to start outgoing call alert: $e');
    }
  }

  Future<void> _stopCallAlertSafely() async {
    try {
      await _stopCallAlertUseCase?.call();
    } catch (e) {
      debugPrint('[CallsBloc] Failed to stop call alert: $e');
    }
  }

  @override
  Future<void> close() async {
    await _callKitEventBridge?.close();
    _callKitEventBridge = null;
    await _incomingCallsSubscription?.cancel();
    _incomingCallsSubscription = null;
    await _cleanup();
    return super.close();
  }
}
