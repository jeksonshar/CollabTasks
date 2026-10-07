import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/models/call_data_entity.dart';
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
  final List<RtcParticipantMediaState> participantMediaStates;
  final String? errorMessage;
  final String? currentUserId;

  const CallsState({
    this.status = CallsStatus.idle,
    this.activeCall,
    this.session,
    this.rtcConnectionState = RtcConnectionState.disconnected,
    this.isMicrophoneMuted = false,
    this.isSpeakerEnabled = false,
    this.isCameraEnabled = true,
    this.participantMediaStates = const [],
    this.errorMessage,
    this.currentUserId,
  });

  CallsState copyWith({
    CallsStatus? status,
    Call? Function()? activeCall,
    CallSession? Function()? session,
    RtcConnectionState? rtcConnectionState,
    bool? isMicrophoneMuted,
    bool? isSpeakerEnabled,
    bool? isCameraEnabled,
    List<RtcParticipantMediaState>? participantMediaStates,
    String? Function()? errorMessage,
    String? Function()? currentUserId,
  }) {
    return CallsState(
      status: status ?? this.status,
      activeCall: activeCall != null ? activeCall() : this.activeCall,
      session: session != null ? session() : this.session,
      rtcConnectionState: rtcConnectionState ?? this.rtcConnectionState,
      isMicrophoneMuted: isMicrophoneMuted ?? this.isMicrophoneMuted,
      isSpeakerEnabled: isSpeakerEnabled ?? this.isSpeakerEnabled,
      isCameraEnabled: isCameraEnabled ?? this.isCameraEnabled,
      participantMediaStates: participantMediaStates ?? this.participantMediaStates,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      currentUserId: currentUserId != null ? currentUserId() : this.currentUserId,
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
    participantMediaStates,
    errorMessage,
    currentUserId,
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
  }) : super(status: CallsStatus.active, session: session);

  @override
  List<Object?> get props => [...super.props, callData];
}

/// Emitted when a native call action ends the current call.
class CallEndedState extends CallsState {
  final String? callId;

  const CallEndedState({this.callId, super.currentUserId}) : super();

  @override
  List<Object?> get props => [...super.props, callId];
}
