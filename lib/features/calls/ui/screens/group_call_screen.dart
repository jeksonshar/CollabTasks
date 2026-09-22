import 'dart:async';

import 'package:collab_tasks/features/calls/domain/models/call_participant.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_connection_state.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_participant_media_state.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_bloc.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_event.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_state.dart';
import 'package:collab_tasks/features/calls/ui/widgets/rtc_video_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GroupCallScreen extends StatefulWidget {
  final String callId;
  final String groupName;
  final CallType callType;

  const GroupCallScreen({
    super.key,
    required this.callId,
    required this.groupName,
    required this.callType,
  });

  @override
  State<GroupCallScreen> createState() => _GroupCallScreenState();
}

class _GroupCallScreenState extends State<GroupCallScreen> with WidgetsBindingObserver {
  Timer? _durationTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<CallsBloc>().add(AppLifecycleChanged(state));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _durationTimer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    if (_durationTimer != null && _durationTimer!.isActive) return;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _stopTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _onLeaveCallPressed() {
    context.read<CallsBloc>().add(const LeaveCallRequested());
  }

  void _onEndCallPressed() {
    final activeCallId = context.read<CallsBloc>().state.activeCall?.id ?? widget.callId;
    context.read<CallsBloc>().add(EndCallRequested(callId: activeCallId));
  }

  void _showInviteDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite Participant'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter user ID or name',
            labelText: 'Participant',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final id = textController.text.trim();
              if (id.isNotEmpty) {
                context.read<CallsBloc>().add(
                  InviteParticipantRequested(userId: id, displayName: 'User $id'),
                );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<CallsBloc, CallsState>(
      listener: (context, state) {
        if (state.status == CallsStatus.active &&
            state.rtcConnectionState == RtcConnectionState.connected) {
          _startTimerIfNeeded();
        } else if (state.status != CallsStatus.active) {
          _stopTimer();
        }

        if (state.status == CallsStatus.idle) {
          Navigator.of(context).pop();
        } else if (state.status == CallsStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Call error'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final localUserId = state.currentUserId ?? '';
        final isHost =
            state.activeCall?.callerId == localUserId ||
            (state.activeCall?.participants.any(
                  (p) => p.userId == localUserId && p.role == CallParticipantRole.host,
                ) ??
                false);

        // Merge domain participants with RTC media states
        final participants = state.activeCall?.participants ?? [];

        final canAutoPop = state.status == CallsStatus.idle || state.status == CallsStatus.error;

        return PopScope(
          canPop: canAutoPop,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop &&
                (state.status == CallsStatus.active ||
                    state.status == CallsStatus.ringingOutgoing)) {
              _onLeaveCallPressed();
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF12121A),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.groupName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        state.rtcConnectionState == RtcConnectionState.connected
                            ? _formatDuration(_elapsedSeconds)
                            : state.rtcConnectionState.name,
                        style: TextStyle(
                          color: state.rtcConnectionState == RtcConnectionState.connected
                              ? Colors.greenAccent
                              : Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${participants.length} participants',
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                  tooltip: 'Invite',
                  onPressed: () => _showInviteDialog(context),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Leave Call',
                  onPressed: _onLeaveCallPressed,
                ),
              ],
            ),
            body: Column(
              children: [
                // Reconnecting warning banner
                if (state.rtcConnectionState == RtcConnectionState.reconnecting)
                  Container(
                    width: double.infinity,
                    color: Colors.amber.shade900,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: const Text(
                      'Reconnecting...',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),

                // Participant Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildParticipantGrid(context, state, participants, localUserId),
                  ),
                ),

                // Controls Bar
                _buildControlsBar(context, state, isHost),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticipantGrid(
    BuildContext context,
    CallsState state,
    List<CallParticipant> participants,
    String localUserId,
  ) {
    if (participants.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.white54));
    }

    final count = participants.length;
    final crossAxisCount = count <= 2 ? 1 : 2;

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: count == 1 ? 1.4 : 1.0,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        final participant = participants[index];
        final isLocal = participant.userId == localUserId;

        final mediaState = state.participantMediaStates.firstWhere(
          (m) => m.participantId == participant.userId || (isLocal && m.isLocal),
          orElse: () => RtcParticipantMediaState(
            participantId: participant.userId,
            isLocal: isLocal,
            isAudioMuted: isLocal ? state.isMicrophoneMuted : false,
            isVideoEnabled: isLocal ? state.isCameraEnabled : false,
          ),
        );

        final isSpeaking = mediaState.isSpeaking;
        final isVideoEnabled =
            widget.callType == CallType.video &&
            (isLocal ? state.isCameraEnabled : mediaState.isVideoEnabled);

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSpeaking ? Colors.green : Colors.transparent, width: 2.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video View or Avatar Fallback
              if (isVideoEnabled)
                RtcVideoView(
                  participantId: participant.userId,
                  isLocal: isLocal,
                  fit: BoxFit.cover,
                  mirror: isLocal,
                )
              else
                Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white12,
                    backgroundImage: participant.avatarUrl != null
                        ? NetworkImage(participant.avatarUrl!)
                        : null,
                    child: participant.avatarUrl == null
                        ? Text(
                            participant.displayName.isNotEmpty
                                ? participant.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),

              // Bottom participant name tag
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isLocal ? '${participant.displayName} (You)' : participant.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    // Mute icon
                    if (isLocal ? state.isMicrophoneMuted : mediaState.isAudioMuted)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic_off, size: 14, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlsBar(BuildContext context, CallsState state, bool isHost) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mic mute toggle
            IconButton.filledTonal(
              iconSize: 26,
              padding: const EdgeInsets.all(12),
              style: IconButton.styleFrom(
                backgroundColor: state.isMicrophoneMuted
                    ? Colors.red.withValues(alpha: 0.3)
                    : Colors.white24,
              ),
              icon: Icon(
                state.isMicrophoneMuted ? Icons.mic_off : Icons.mic,
                color: state.isMicrophoneMuted ? Colors.redAccent : Colors.white,
              ),
              tooltip: state.isMicrophoneMuted ? 'Unmute' : 'Mute',
              onPressed: () {
                context.read<CallsBloc>().add(const ToggleMicrophoneRequested());
              },
            ),

            // Video toggle (if video call)
            if (widget.callType == CallType.video) ...[
              IconButton.filledTonal(
                iconSize: 26,
                padding: const EdgeInsets.all(12),
                style: IconButton.styleFrom(
                  backgroundColor: !state.isCameraEnabled
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.white24,
                ),
                icon: Icon(
                  state.isCameraEnabled ? Icons.videocam : Icons.videocam_off,
                  color: !state.isCameraEnabled ? Colors.redAccent : Colors.white,
                ),
                tooltip: state.isCameraEnabled ? 'Disable Camera' : 'Enable Camera',
                onPressed: () {
                  context.read<CallsBloc>().add(const ToggleCameraRequested());
                },
              ),
              IconButton.filledTonal(
                iconSize: 26,
                padding: const EdgeInsets.all(12),
                style: IconButton.styleFrom(backgroundColor: Colors.white24),
                icon: const Icon(Icons.cameraswitch, color: Colors.white),
                tooltip: 'Switch Camera',
                onPressed: state.isCameraEnabled
                    ? () {
                        context.read<CallsBloc>().add(const SwitchCameraRequested());
                      }
                    : null,
              ),
            ],

            // Leave call button
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.shade900,
                foregroundColor: Colors.white,
              ),
              onPressed: _onLeaveCallPressed,
              icon: const Icon(Icons.call_end, size: 20),
              label: const Text('Leave'),
            ),

            // End call for all (Host only)
            if (isHost)
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.red),
                icon: const Icon(Icons.power_settings_new, color: Colors.white),
                tooltip: 'End for All',
                onPressed: _onEndCallPressed,
              ),
          ],
        ),
      ),
    );
  }
}
