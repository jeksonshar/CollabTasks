import 'dart:async';

import 'package:collab_tasks/features/calls/domain/models/call_participant.dart';
import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
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
import 'package:collab_tasks/features/calls/ui/blocs/calls_event.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CallsBloc extends Bloc<CallsEvent, CallsState> {
  final StartCallUseCase _startCallUseCase;
  final AcceptCallUseCase _acceptCallUseCase;
  final RejectCallUseCase _rejectCallUseCase;
  final EndCallUseCase _endCallUseCase;
  final CancelCallUseCase _cancelCallUseCase;
  final LeaveCallUseCase _leaveCallUseCase;
  final InviteParticipantUseCase _inviteParticipantUseCase;
  final RequestCallPermissionsUseCase _requestCallPermissionsUseCase;
  final GetCallSessionUseCase _getCallSessionUseCase;
  final WatchActiveCallUseCase _watchActiveCallUseCase;
  final WatchIncomingCallsUseCase _watchIncomingCallsUseCase;
  final JoinRtcSessionUseCase _joinRtcSessionUseCase;
  final LeaveRtcSessionUseCase _leaveRtcSessionUseCase;
  final ToggleMicrophoneUseCase _toggleMicrophoneUseCase;
  final ToggleCameraUseCase _toggleCameraUseCase;
  final ToggleSpeakerUseCase _toggleSpeakerUseCase;
  final SwitchCameraUseCase _switchCameraUseCase;
  final WatchRtcConnectionStateUseCase _watchRtcConnectionStateUseCase;
  final WatchRtcParticipantMediaStatesUseCase _watchRtcParticipantMediaStatesUseCase;
  final StartIncomingAlertUseCase? _startIncomingAlertUseCase;
  final StartOutgoingAlertUseCase? _startOutgoingAlertUseCase;
  final StopCallAlertUseCase? _stopCallAlertUseCase;

  StreamSubscription? _activeCallSubscription;
  StreamSubscription? _incomingCallsSubscription;
  StreamSubscription? _rtcConnectionStateSubscription;
  StreamSubscription? _participantMediaStatesSubscription;
  Timer? _outgoingCallTimeoutTimer;

  static const Duration _outgoingCallTimeoutDuration = Duration(seconds: 45);

  CallsBloc({
    required StartCallUseCase startCallUseCase,
    required AcceptCallUseCase acceptCallUseCase,
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
       _rejectCallUseCase = rejectCallUseCase,
       _endCallUseCase = endCallUseCase,
       _cancelCallUseCase = cancelCallUseCase,
       _leaveCallUseCase = leaveCallUseCase,
       _inviteParticipantUseCase = inviteParticipantUseCase,
       _requestCallPermissionsUseCase = requestCallPermissionsUseCase,
       _getCallSessionUseCase = getCallSessionUseCase,
       _watchActiveCallUseCase = watchActiveCallUseCase,
       _watchIncomingCallsUseCase = watchIncomingCallsUseCase,
       _joinRtcSessionUseCase = joinRtcSessionUseCase,
       _leaveRtcSessionUseCase = leaveRtcSessionUseCase,
       _toggleMicrophoneUseCase = toggleMicrophoneUseCase,
       _toggleCameraUseCase = toggleCameraUseCase,
       _toggleSpeakerUseCase = toggleSpeakerUseCase,
       _switchCameraUseCase = switchCameraUseCase,
       _watchRtcConnectionStateUseCase = watchRtcConnectionStateUseCase,
       _watchRtcParticipantMediaStatesUseCase = watchRtcParticipantMediaStatesUseCase,
       _startIncomingAlertUseCase = startIncomingAlertUseCase,
       _startOutgoingAlertUseCase = startOutgoingAlertUseCase,
       _stopCallAlertUseCase = stopCallAlertUseCase,
       super(const CallsState()) {
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
  }

  Future<void> _onStartCall(StartCallRequested event, Emitter<CallsState> emit) async {
    debugPrint('[CallsBloc] _onStartCall: type=${event.type}, callee=${event.calleeIds}');
    try {
      final permissionsGranted = await _requestCallPermissionsUseCase(type: event.type);
      if (!permissionsGranted) {
        debugPrint('[CallsBloc] Permissions denied for call type: ${event.type}');
        await _stopCallAlertSafely();
        emit(
          state.copyWith(
            status: CallsStatus.error,
            errorMessage: () => event.type == CallType.video
                ? 'Camera and microphone permissions are required for video calls'
                : 'Microphone permission is required for calls',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: CallsStatus.ringingOutgoing,
          currentUserId: () => event.callerId,
          isCameraEnabled: event.type == CallType.video,
          errorMessage: () => null,
        ),
      );
      await _startOutgoingAlertSafely();

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

      _startOutgoingCallTimeout();
      await _subscribeToActiveCall(call.id);
    } catch (e, st) {
      debugPrint('[CallsBloc] Error starting call: $e\n$st');
      await _stopCallAlertSafely();
      emit(state.copyWith(status: CallsStatus.error, errorMessage: () => e.toString()));
    }
  }

  Future<void> _onIncomingCallDetected(IncomingCallDetected event, Emitter<CallsState> emit) async {
    if (state.status != CallsStatus.idle) return;

    emit(
      state.copyWith(
        status: CallsStatus.ringingIncoming,
        activeCall: () => event.call,
        errorMessage: () => null,
      ),
    );

    await _subscribeToActiveCall(event.call.id);
  }

  Future<void> _onIncomingCallDialogOpened(
    IncomingCallDialogOpened event,
    Emitter<CallsState> emit,
  ) async {
    if (state.status != CallsStatus.ringingIncoming || state.activeCall?.id != event.callId) {
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
    await _stopCallAlertSafely();
    try {
      final callType = state.activeCall?.type ?? CallType.audio;
      final permissionsGranted = await _requestCallPermissionsUseCase(type: callType);
      if (!permissionsGranted) {
        await _stopCallAlertSafely();
        emit(
          state.copyWith(
            status: CallsStatus.error,
            errorMessage: () => callType == CallType.video
                ? 'Camera and microphone permissions are required for video calls'
                : 'Microphone permission is required for calls',
          ),
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

      emit(state.copyWith(session: () => session));

      await _joinRtcSession(session);
    } catch (e) {
      await _cleanup();
      emit(state.copyWith(status: CallsStatus.error, errorMessage: () => e.toString()));
    }
  }

  Future<void> _onRejectCall(RejectCallRequested event, Emitter<CallsState> emit) async {
    try {
      await _rejectCallUseCase(callId: event.callId, userId: event.userId);
    } catch (e) {
      // Ignored on reject
    } finally {
      await _cleanup();
      emit(const CallsState());
    }
  }

  Future<void> _onEndCall(EndCallRequested event, Emitter<CallsState> emit) async {
    final callId = event.callId ?? state.activeCall?.id;
    emit(state.copyWith(status: CallsStatus.terminating));

    if (callId != null) {
      try {
        await _endCallUseCase(callId);
      } catch (e) {
        // Ignored on end
      }
    }

    await _cleanup();
    emit(const CallsState());
  }

  Future<void> _onCancelCall(CancelCallRequested event, Emitter<CallsState> emit) async {
    final callId = event.callId ?? state.activeCall?.id;
    emit(state.copyWith(status: CallsStatus.terminating));

    if (callId != null) {
      try {
        await _cancelCallUseCase(callId);
      } catch (_) {}
    }

    await _cleanup();
    emit(const CallsState());
  }

  Future<void> _onLeaveCall(LeaveCallRequested event, Emitter<CallsState> emit) async {
    final callId = state.activeCall?.id;
    final userId = state.currentUserId;
    emit(state.copyWith(status: CallsStatus.terminating));

    if (callId != null && userId != null) {
      try {
        await _leaveCallUseCase(callId: callId, userId: userId);
      } catch (_) {}
    }

    await _cleanup();
    emit(const CallsState());
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
      } catch (e) {
        emit(
          state.copyWith(
            status: CallsStatus.error,
            errorMessage: () => 'Failed to invite participant: $e',
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
        if (state.isCameraEnabled && state.activeCall?.type == CallType.video) {
          await _toggleCameraUseCase(false);
          emit(state.copyWith(isCameraEnabled: false));
        }
        break;
      case AppLifecycleState.resumed:
        if (!state.isCameraEnabled && state.activeCall?.type == CallType.video) {
          await _toggleCameraUseCase(true);
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
    await _toggleMicrophoneUseCase(newMuted);
    emit(state.copyWith(isMicrophoneMuted: newMuted));
  }

  Future<void> _onToggleCamera(ToggleCameraRequested event, Emitter<CallsState> emit) async {
    final newEnabled = !state.isCameraEnabled;
    await _toggleCameraUseCase(newEnabled);
    emit(state.copyWith(isCameraEnabled: newEnabled));
  }

  Future<void> _onToggleSpeaker(ToggleSpeakerRequested event, Emitter<CallsState> emit) async {
    final newEnabled = !state.isSpeakerEnabled;
    await _toggleSpeakerUseCase(newEnabled);
    emit(state.copyWith(isSpeakerEnabled: newEnabled));
  }

  Future<void> _onSwitchCamera(SwitchCameraRequested event, Emitter<CallsState> emit) async {
    await _switchCameraUseCase();
  }

  void _onListenIncomingCallsStarted(ListenIncomingCallsStarted event, Emitter<CallsState> emit) {
    debugPrint('[CallsBloc] Starting incoming calls listener for: ${event.userId}');
    _incomingCallsSubscription?.cancel();
    final normalizedUserId = event.userId.trim().toLowerCase();

    _incomingCallsSubscription = _watchIncomingCallsUseCase(normalizedUserId).listen(
      (calls) {
        debugPrint('[CallsBloc] Received incoming calls update: ${calls.length} call(s)');
        for (final call in calls) {
          if (call.status == CallStatus.ringing &&
              call.callerId.trim().toLowerCase() != normalizedUserId &&
              call.calleeIds.any((id) => id.trim().toLowerCase() == normalizedUserId) &&
              call.participants.any(
                (p) =>
                    p.userId.trim().toLowerCase() == normalizedUserId &&
                    p.status == CallParticipantStatus.ringing,
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

  void _onStopListeningIncomingCalls(StopListeningIncomingCalls event, Emitter<CallsState> emit) {
    debugPrint('[CallsBloc] Stopping incoming calls listener');
    _incomingCallsSubscription?.cancel();
    _incomingCallsSubscription = null;
  }

  Future<void> _onCallTimeoutOccurred(CallTimeoutOccurred event, Emitter<CallsState> emit) async {
    if (state.status != CallsStatus.ringingOutgoing) return;
    debugPrint('[CallsBloc] Outgoing call timed out (no answer)');

    final callId = state.activeCall?.id;
    if (callId != null) {
      try {
        await _cancelCallUseCase(callId);
      } catch (e) {
        debugPrint('[CallsBloc] Error cancelling timed-out call: $e');
      }
    }

    await _cleanup();
    emit(state.copyWith(status: CallsStatus.error, errorMessage: () => 'Recipient did not answer'));
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
    if (call == null) {
      debugPrint('[CallsBloc] Active call updated to null -> cleaning up');
      await _cleanup();
      emit(const CallsState());
      return;
    }

    debugPrint('[CallsBloc] Active call updated: id=${call.id}, status=${call.status}');
    emit(state.copyWith(activeCall: () => call));

    // Caller scenario: callee accepted -> transition from ringing to active & join RTC
    if (state.status == CallsStatus.ringingOutgoing && call.status == CallStatus.active) {
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
        await _cleanup();
        emit(state.copyWith(status: CallsStatus.error, errorMessage: () => e.toString()));
      }
    } else if (call.status == CallStatus.rejected) {
      debugPrint('[CallsBloc] Call was rejected by recipient');
      await _cleanup();
      emit(state.copyWith(status: CallsStatus.error, errorMessage: () => 'Call was declined'));
    } else if (call.status == CallStatus.ended || call.status == CallStatus.cancelled) {
      debugPrint('[CallsBloc] Call ended or cancelled');
      await _cleanup();
      emit(const CallsState());
    }
  }

  Future<void> _onRtcConnectionStateChanged(
    RtcConnectionStateChanged event,
    Emitter<CallsState> emit,
  ) async {
    debugPrint('[CallsBloc] RTC Connection state changed: ${event.state}');
    emit(state.copyWith(rtcConnectionState: event.state));

    if (event.state == RtcConnectionState.failed) {
      debugPrint(
        '[CallsBloc] RTC connection failed, explicitly calling leaveSession to release microphone...',
      );
      try {
        await _leaveRtcSessionUseCase();
      } catch (e) {
        debugPrint('[CallsBloc] Error leaving RTC session on failed state: $e');
      }
      await _cleanup();
      emit(
        state.copyWith(
          status: CallsStatus.error,
          errorMessage: () => 'RTC connection failed. Check network or RTC settings.',
        ),
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
    await _activeCallSubscription?.cancel();
    _activeCallSubscription = _watchActiveCallUseCase(callId).listen(
      (call) => add(ActiveCallUpdated(call)),
      onError: (err) {
        debugPrint('[CallsBloc] Error watching active call: $err');
        add(const ActiveCallUpdated(null));
      },
    );
  }

  Future<void> _joinRtcSession(CallSession session) async {
    await _subscribeToRtcStreams();
    await _joinRtcSessionUseCase(session);
  }

  Future<void> _subscribeToRtcStreams() async {
    await _rtcConnectionStateSubscription?.cancel();
    _rtcConnectionStateSubscription = _watchRtcConnectionStateUseCase().listen(
      (rtcState) => add(RtcConnectionStateChanged(rtcState)),
    );

    await _participantMediaStatesSubscription?.cancel();
    _participantMediaStatesSubscription = _watchRtcParticipantMediaStatesUseCase().listen(
      (mediaStates) => add(ParticipantMediaStatesUpdated(mediaStates)),
    );
  }

  Future<void> _cleanup() async {
    _stopOutgoingCallTimeout();
    await _stopCallAlertSafely();

    await _activeCallSubscription?.cancel();
    _activeCallSubscription = null;

    await _rtcConnectionStateSubscription?.cancel();
    _rtcConnectionStateSubscription = null;

    await _participantMediaStatesSubscription?.cancel();
    _participantMediaStatesSubscription = null;

    try {
      await _leaveRtcSessionUseCase();
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
    await _incomingCallsSubscription?.cancel();
    _incomingCallsSubscription = null;
    await _cleanup();
    return super.close();
  }
}
