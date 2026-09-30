import 'dart:async';

import 'package:collab_tasks/features/calls/domain/models/call_data_entity.dart';
import 'package:collab_tasks/features/calls/domain/models/call_participant.dart';
import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
import 'package:collab_tasks/features/calls/domain/models/call_status.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_connection_state.dart';
import 'package:collab_tasks/features/calls/domain/services/call_kit_service.dart';
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
import 'package:collab_tasks/features/calls/domain/usecases/accept_incoming_call_usecase.dart';
import 'package:collab_tasks/features/calls/domain/usecases/cancel_incoming_call_usecase.dart';
import 'package:collab_tasks/features/calls/domain/usecases/decline_incoming_call_usecase.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_event.dart';
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
  StreamSubscription<CallEvent?>? _callKitEventSubscription;
  Timer? _outgoingCallTimeoutTimer;
  final Set<String> _callKitDismissalsPending = {};
  final Set<String> _acceptedCallKitIds = {};
  final Set<String> _pendingCallKitAcceptIds = {};
  final Set<String> _resolvedIncomingCallIds = {};
  final List<CallEvent> _pendingCallKitEvents = [];
  final List<CallDataEntity> _pendingAcceptedCallKitCalls = [];
  final List<CallDataEntity> _pendingDeclinedCallKitCalls = [];

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
    on<CallKitEventReceived>(_onCallKitEventReceived);
    on<CallKitAccepted>(_onCallKitAccepted);
    on<CallKitDeclined>(_onCallKitDeclined);
    on<CallCancellationPushReceived>(_onCallCancellationPushReceived);
    _callKitEventSubscription = callKitEvents?.listen(
      (event) {
        if (event != null) add(CallKitEventReceived(event));
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[CallsBloc] CallKit event stream error: $error\n$stackTrace');
      },
    );
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
    if (!_acceptedCallKitIds.add(event.callId)) return;
    _resolvedIncomingCallIds.add(event.callId);
    await _stopCallAlertSafely();
    try {
      final callType = state.activeCall?.type ?? CallType.audio;
      final permissionsGranted = await _requestCallPermissionsUseCase(type: callType);
      if (!permissionsGranted) {
        _acceptedCallKitIds.remove(event.callId);
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
          currentUserId: event.userId,
        ),
      );

      await _joinRtcSession(session);
    } catch (e) {
      _acceptedCallKitIds.remove(event.callId);
      await _cleanup();
      emit(state.copyWith(status: CallsStatus.error, errorMessage: () => e.toString()));
    }
  }

  Future<void> _onRejectCall(RejectCallRequested event, Emitter<CallsState> emit) async {
    _resolvedIncomingCallIds.add(event.callId);
    try {
      await _rejectCallUseCase(callId: event.callId, userId: event.userId);
    } catch (e) {
      // Ignored on reject
    } finally {
      await _cleanup();
      emit(CallsState(currentUserId: state.currentUserId));
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
      await _dismissCallKitCall(callId);
    }

    await _cleanup();
    emit(CallsState(currentUserId: state.currentUserId));
  }

  Future<void> _onCancelCall(CancelCallRequested event, Emitter<CallsState> emit) async {
    final callId = event.callId ?? state.activeCall?.id;
    emit(state.copyWith(status: CallsStatus.terminating));

    if (callId != null) {
      try {
        await _cancelCallUseCase(callId);
      } catch (_) {}
      await _dismissCallKitCall(callId);
    }

    await _cleanup();
    emit(CallsState(currentUserId: state.currentUserId));
  }

  Future<void> _onLeaveCall(LeaveCallRequested event, Emitter<CallsState> emit) async {
    final callId = state.activeCall?.id;
    final userId = state.currentUserId;
    emit(state.copyWith(status: CallsStatus.terminating));

    if (callId != null && userId != null) {
      try {
        await _leaveCallUseCase(callId: callId, userId: userId);
      } catch (_) {}
      await _dismissCallKitCall(callId);
    }

    await _cleanup();
    emit(CallsState(currentUserId: state.currentUserId));
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

  Future<void> _onCallKitEventReceived(CallKitEventReceived event, Emitter<CallsState> emit) async {
    final nativeEvent = event.event;
    final callData = switch (nativeEvent) {
      CallEventActionCallAccept() => _callDataFromParams(nativeEvent.callKitParams),
      CallEventActionCallDecline() => _callDataFromParams(nativeEvent.callKitParams),
      _ => null,
    };
    if (nativeEvent is CallEventActionCallAccept) {
      if (_acceptedCallKitIds.contains(nativeEvent.callKitParams.id)) return;
      _pendingCallKitAcceptIds.add(nativeEvent.callKitParams.id);
    }
    final requiresUser =
        nativeEvent is CallEventActionCallAccept || nativeEvent is CallEventActionCallDecline;
    final recipientId = nativeEvent is CallEventActionCallDecline
        ? _resolveCallRecipientId(callData)
        : state.currentUserId?.trim() ?? '';
    if (requiresUser && recipientId.isEmpty) {
      _pendingCallKitEvents.add(nativeEvent);
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
      await _endCallFromCallKit(nativeEvent.id, emit);
      return;
    }

    if (nativeEvent is CallEventActionCallEnded) {
      await _endCallFromCallKit(nativeEvent.callKitParams.id, emit);
    }
  }

  Future<void> _onCallKitAccepted(CallKitAccepted event, Emitter<CallsState> emit) async {
    if (_acceptedCallKitIds.contains(event.callData.callId)) return;
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
    if (callId.isEmpty) return;
    _resolvedIncomingCallIds.add(callId);
    final recipientId = userId ?? state.currentUserId ?? callData.calleeId;
    if (recipientId.trim().isEmpty || _declineIncomingCallUseCase == null) {
      _resolvedIncomingCallIds.remove(callId);
      emit(
        state.copyWith(
          status: CallsStatus.error,
          errorMessage: () => 'Unable to identify the call recipient',
        ),
      );
      return;
    }
    try {
      _callKitDismissalsPending.add(callId);
      await _declineIncomingCallUseCase.call(callId: callId, userId: recipientId);
      await _cleanup();
      emit(CallEndedState(callId: callId, currentUserId: state.currentUserId));
    } catch (error, stackTrace) {
      _resolvedIncomingCallIds.remove(callId);
      _callKitDismissalsPending.remove(callId);
      debugPrint('[CallsBloc] Failed to decline CallKit call: $error\n$stackTrace');
      emit(state.copyWith(status: CallsStatus.error, errorMessage: () => error.toString()));
    }
  }

  Future<void> _onCallCancellationPushReceived(
    CallCancellationPushReceived event,
    Emitter<CallsState> emit,
  ) async {
    if (event.callId.isEmpty) return;
    _resolvedIncomingCallIds.add(event.callId);
    _pendingCallKitAcceptIds.remove(event.callId);
    _callKitDismissalsPending.add(event.callId);
    try {
      await _cancelIncomingCallUseCase?.call(event.callId);
    } catch (error) {
      debugPrint('[CallsBloc] Failed to dismiss remotely cancelled call: $error');
    }

    final currentState = state;
    var activeCallId = currentState.activeCall?.id;
    if (currentState is CallAcceptedState) {
      activeCallId = currentState.callData.callId;
    }
    if (activeCallId == event.callId ||
        (state.status == CallsStatus.ringingIncoming && state.activeCall?.id == event.callId)) {
      await _cleanup();
      emit(CallEndedState(currentUserId: state.currentUserId));
    }
  }

  Future<void> _acceptCallKitData(CallDataEntity callData, Emitter<CallsState> emit) async {
    if (!_acceptedCallKitIds.add(callData.callId)) return;
    _pendingCallKitAcceptIds.remove(callData.callId);
    _resolvedIncomingCallIds.add(callData.callId);
    await _stopCallAlertSafely();
    final userId = state.currentUserId;
    final useCase = _acceptIncomingCallUseCase;
    if (useCase == null || userId == null || userId.isEmpty) {
      _acceptedCallKitIds.remove(callData.callId);
      emit(
        state.copyWith(
          status: CallsStatus.error,
          errorMessage: () => 'Unable to identify the call recipient',
        ),
      );
      return;
    }
    try {
      final granted = await _requestCallPermissionsUseCase(type: callData.callType);
      if (!granted) {
        _callKitDismissalsPending.add(callData.callId);
        await _declineIncomingCallUseCase?.call(callId: callData.callId, userId: userId);
        emit(
          state.copyWith(
            status: CallsStatus.error,
            errorMessage: () => 'Call permissions were denied',
          ),
        );
        return;
      }
      _callKitDismissalsPending.add(callData.callId);
      // Native CallKit acceptance does not pass through IncomingCallDetected,
      // so establish the Firestore watcher here as well. It must stay active
      // to observe the caller ending the accepted call.
      await _subscribeToActiveCall(callData.callId);
      final session = await useCase(callData: callData, userId: userId);
      emit(CallAcceptedState(callData: callData, session: session, currentUserId: userId));
      await _joinRtcSession(session);
    } catch (error, stackTrace) {
      _acceptedCallKitIds.remove(callData.callId);
      _callKitDismissalsPending.remove(callData.callId);
      debugPrint('[CallsBloc] Failed to accept CallKit call: $error\n$stackTrace');
      await _cleanup();
      emit(state.copyWith(status: CallsStatus.error, errorMessage: () => error.toString()));
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

  Future<void> _endCallFromCallKit(String callId, Emitter<CallsState> emit) async {
    if (_callKitDismissalsPending.remove(callId)) return;
    _resolvedIncomingCallIds.add(callId);
    _acceptedCallKitIds.remove(callId);
    _pendingCallKitAcceptIds.remove(callId);
    _callKitDismissalsPending.add(callId);
    try {
      await _cancelIncomingCallUseCase?.call(callId);
    } catch (error) {
      debugPrint('[CallsBloc] Failed to clear CallKit call: $error');
    }
    await _cleanup();
    emit(CallEndedState(callId: callId, currentUserId: state.currentUserId));
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
      emit(CallsState(currentUserId: state.currentUserId));
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
      // A rejected call is terminal, so return to idle instead of leaving the
      // Bloc in error where _onIncomingCallDetected would ignore new calls.
      emit(CallsState(currentUserId: state.currentUserId));
    } else if (call.status == CallStatus.ended || call.status == CallStatus.cancelled) {
      debugPrint('[CallsBloc] Call ended or cancelled');
      await _cleanup();
      emit(CallsState(currentUserId: state.currentUserId));
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
      if (state.status == CallsStatus.error || state.status == CallsStatus.idle) {
        debugPrint('[CallsBloc] RTC failed event ignored — already in ${state.status}');
        return;
      }
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
    await _callKitEventSubscription?.cancel();
    _callKitEventSubscription = null;
    await _incomingCallsSubscription?.cancel();
    _incomingCallsSubscription = null;
    await _cleanup();
    return super.close();
  }
}
