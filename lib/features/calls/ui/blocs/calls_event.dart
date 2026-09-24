import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_connection_state.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_participant_media_state.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

sealed class CallsEvent extends Equatable {
  const CallsEvent();

  @override
  List<Object?> get props => [];
}

class StartCallRequested extends CallsEvent {
  final String? callId;
  final String callerId;
  final String callerName;
  final String? callerAvatarUrl;
  final List<String> calleeIds;
  final CallType type;
  final bool isGroup;
  final String? groupId;

  const StartCallRequested({
    this.callId,
    required this.callerId,
    required this.callerName,
    this.callerAvatarUrl,
    required this.calleeIds,
    required this.type,
    this.isGroup = false,
    this.groupId,
  });

  @override
  List<Object?> get props => [
    callId,
    callerId,
    callerName,
    callerAvatarUrl,
    calleeIds,
    type,
    isGroup,
    groupId,
  ];
}

class IncomingCallDetected extends CallsEvent {
  final Call call;

  const IncomingCallDetected(this.call);

  @override
  List<Object?> get props => [call];
}

class IncomingCallDialogOpened extends CallsEvent {
  final String callId;

  const IncomingCallDialogOpened(this.callId);

  @override
  List<Object?> get props => [callId];
}

class StopCallAlertRequested extends CallsEvent {
  const StopCallAlertRequested();
}

class AcceptCallRequested extends CallsEvent {
  final String callId;
  final String userId;

  const AcceptCallRequested({required this.callId, required this.userId});

  @override
  List<Object?> get props => [callId, userId];
}

class RejectCallRequested extends CallsEvent {
  final String callId;
  final String userId;

  const RejectCallRequested({required this.callId, required this.userId});

  @override
  List<Object?> get props => [callId, userId];
}

class EndCallRequested extends CallsEvent {
  final String? callId;

  const EndCallRequested({this.callId});

  @override
  List<Object?> get props => [callId];
}

class ToggleMicrophoneRequested extends CallsEvent {
  const ToggleMicrophoneRequested();
}

class ToggleCameraRequested extends CallsEvent {
  const ToggleCameraRequested();
}

class ToggleSpeakerRequested extends CallsEvent {
  const ToggleSpeakerRequested();
}

class SwitchCameraRequested extends CallsEvent {
  const SwitchCameraRequested();
}

class ActiveCallUpdated extends CallsEvent {
  final Call? call;

  const ActiveCallUpdated(this.call);

  @override
  List<Object?> get props => [call];
}

class RtcConnectionStateChanged extends CallsEvent {
  final RtcConnectionState state;

  const RtcConnectionStateChanged(this.state);

  @override
  List<Object?> get props => [state];
}

class ParticipantMediaStatesUpdated extends CallsEvent {
  final List<RtcParticipantMediaState> mediaStates;

  const ParticipantMediaStatesUpdated(this.mediaStates);

  @override
  List<Object?> get props => [mediaStates];
}

class CancelCallRequested extends CallsEvent {
  final String? callId;

  const CancelCallRequested({this.callId});

  @override
  List<Object?> get props => [callId];
}

class LeaveCallRequested extends CallsEvent {
  const LeaveCallRequested();
}

class InviteParticipantRequested extends CallsEvent {
  final String userId;
  final String displayName;
  final String? avatarUrl;

  const InviteParticipantRequested({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [userId, displayName, avatarUrl];
}

class AppLifecycleChanged extends CallsEvent {
  final AppLifecycleState lifecycleState;

  const AppLifecycleChanged(this.lifecycleState);

  @override
  List<Object?> get props => [lifecycleState];
}

class ListenIncomingCallsStarted extends CallsEvent {
  final String userId;

  const ListenIncomingCallsStarted(this.userId);

  @override
  List<Object?> get props => [userId];
}

class StopListeningIncomingCalls extends CallsEvent {
  const StopListeningIncomingCalls();
}

class CallTimeoutOccurred extends CallsEvent {
  const CallTimeoutOccurred();
}
