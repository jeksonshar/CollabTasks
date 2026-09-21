import 'package:collab_tasks/features/calls/domain/models/call.dart';
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
  final List<RtcParticipantMediaState> participantMediaStates;
  final String? errorMessage;
  final String? currentUserId;

  const CallsState({
    this.status = CallsStatus.idle,
    this.activeCall,
    this.session,
    this.rtcConnectionState = RtcConnectionState.disconnected,
    this.isMicrophoneMuted = false,
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
    isCameraEnabled,
    participantMediaStates,
    errorMessage,
    currentUserId,
  ];
}
