import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/models/call_data_entity.dart';
import 'package:collab_tasks/features/calls/domain/models/call_error_type.dart';
import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_connection_state.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_participant_media_state.dart';
import 'package:equatable/equatable.dart';

enum CallsStatus { idle, ringingOutgoing, ringingIncoming, active, terminating, error }

class CallsState extends Equatable {
  final CallsStatus status;
  final Call? activeCall;
  final CallSession? session;
  final RtcConnectionState rtcConnectionState;
  final bool isMicrophoneMuted;
  final bool isCameraEnabled;
  final bool isSpeakerEnabled;

  /// True only when the user explicitly disabled the camera via the UI toggle.
  /// The lifecycle handler uses this to avoid restoring a camera that the user
  /// intentionally turned off before backgrounding the app.
  final bool isCameraManuallyDisabled;
  final List<RtcParticipantMediaState> participantMediaStates;
  final CallErrorType? errorType;
  final String? errorMessage;
  final String? currentUserId;
  final CallDataEntity? acceptedCallData;
  final int? terminalEventId;

  const CallsState({
    this.status = CallsStatus.idle,
    this.activeCall,
    this.session,
    this.rtcConnectionState = RtcConnectionState.disconnected,
    this.isMicrophoneMuted = false,
    this.isSpeakerEnabled = false,
    this.isCameraEnabled = true,
    this.isCameraManuallyDisabled = false,
    this.participantMediaStates = const [],
    this.errorType,
    this.errorMessage,
    this.currentUserId,
    this.acceptedCallData,
    this.terminalEventId,
  });

  CallsState copyWith({
    CallsStatus? status,
    Call? Function()? activeCall,
    CallSession? Function()? session,
    RtcConnectionState? rtcConnectionState,
    bool? isMicrophoneMuted,
    bool? isSpeakerEnabled,
    bool? isCameraEnabled,
    bool? isCameraManuallyDisabled,
    List<RtcParticipantMediaState>? participantMediaStates,
    CallErrorType? Function()? errorType,
    String? Function()? errorMessage,
    String? Function()? currentUserId,
    CallDataEntity? Function()? acceptedCallData,
    int? terminalEventId,
  }) {
    return CallsState(
      status: status ?? this.status,
      activeCall: activeCall != null ? activeCall() : this.activeCall,
      session: session != null ? session() : this.session,
      rtcConnectionState: rtcConnectionState ?? this.rtcConnectionState,
      isMicrophoneMuted: isMicrophoneMuted ?? this.isMicrophoneMuted,
      isSpeakerEnabled: isSpeakerEnabled ?? this.isSpeakerEnabled,
      isCameraEnabled: isCameraEnabled ?? this.isCameraEnabled,
      isCameraManuallyDisabled: isCameraManuallyDisabled ?? this.isCameraManuallyDisabled,
      participantMediaStates: participantMediaStates ?? this.participantMediaStates,
      errorType: errorType != null ? errorType() : this.errorType,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      currentUserId: currentUserId != null ? currentUserId() : this.currentUserId,
      acceptedCallData: acceptedCallData != null ? acceptedCallData() : this.acceptedCallData,
      terminalEventId: terminalEventId ?? this.terminalEventId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    activeCall,
    session,
    rtcConnectionState,
    isMicrophoneMuted,
    isSpeakerEnabled,
    isCameraEnabled,
    isCameraManuallyDisabled,
    participantMediaStates,
    errorType,
    errorMessage,
    currentUserId,
    acceptedCallData,
    terminalEventId,
  ];
}

/// Emitted after accepting a call from the native CallKit UI or in-app dialog.
class CallAcceptedState extends CallsState {
  final CallDataEntity callData;

  const CallAcceptedState({
    required this.callData,
    required CallSession session,
    super.activeCall,
    super.rtcConnectionState,
    super.isMicrophoneMuted,
    super.isSpeakerEnabled,
    super.isCameraEnabled,
    super.participantMediaStates,
    super.errorMessage,
    super.currentUserId,
  }) : super(status: CallsStatus.active, session: session, acceptedCallData: callData);

  @override
  List<Object?> get props => [...super.props, callData];
}

/// Emitted when a native call action ends the current call.
class CallEndedState extends CallsState {
  final String? callId;

  const CallEndedState({
    this.callId,
    super.currentUserId,
    super.errorType,
    super.errorMessage,
    super.terminalEventId,
  }) : super(status: CallsStatus.idle);

  @override
  List<Object?> get props => [...super.props, callId];
}
