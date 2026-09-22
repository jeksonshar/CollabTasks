import 'dart:async';

import 'package:collab_tasks/features/calls/domain/models/rtc_connection_state.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_participant_media_state.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_bloc.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_event.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_state.dart';
import 'package:collab_tasks/features/calls/ui/widgets/rtc_video_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VideoCallScreen extends StatefulWidget {
  final String callId;
  final String? opponentName;
  final String? opponentAvatarUrl;
  final String? opponentId;

  const VideoCallScreen({
    super.key,
    required this.callId,
    this.opponentName,
    this.opponentAvatarUrl,
    this.opponentId,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> with WidgetsBindingObserver {
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

  void _onEndCallPressed() {
    final activeCallId = context.read<CallsBloc>().state.activeCall?.id ?? widget.callId;
    context.read<CallsBloc>().add(EndCallRequested(callId: activeCallId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = widget.opponentName ?? 'User';

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
              content: Text(state.errorMessage ?? 'Call failed'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final localUserId = state.currentUserId ?? '';
        final opponentId =
            widget.opponentId ??
            state.activeCall?.calleeIds.firstWhere((id) => id != localUserId, orElse: () => '') ??
            '';

        final remoteMediaState = state.participantMediaStates.firstWhere(
          (p) => !p.isLocal,
          orElse: () =>
              RtcParticipantMediaState(participantId: '', isLocal: false, isVideoEnabled: false),
        );

        final isRemoteVideoActive =
            remoteMediaState.isVideoEnabled &&
            state.rtcConnectionState == RtcConnectionState.connected;

        final canAutoPop = state.status == CallsStatus.idle || state.status == CallsStatus.error;

        return PopScope(
          canPop: canAutoPop,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop &&
                (state.status == CallsStatus.active ||
                    state.status == CallsStatus.ringingOutgoing)) {
              _onEndCallPressed();
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                // 1. Remote Video / Fullscreen placeholder
                Positioned.fill(
                  child: isRemoteVideoActive
                      ? RtcVideoView(participantId: opponentId, isLocal: false, fit: BoxFit.cover)
                      : _buildRemoteFallback(context, displayName, state),
                ),

                // 2. Top Header with Call Info & Status
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildStatusHeader(context, state),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            tooltip: 'End Call',
                            onPressed: _onEndCallPressed,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Local Video PiP (Picture in Picture)
                Positioned(
                  top: 90,
                  right: 16,
                  width: 110,
                  height: 160,
                  child: _buildLocalPip(context, state, localUserId),
                ),

                // 4. Reconnecting banner overlay
                if (state.rtcConnectionState == RtcConnectionState.reconnecting)
                  Positioned(
                    top: 80,
                    left: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade900.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Connection unstable, reconnecting...',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 5. Bottom Control Bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      child: _buildControlsBar(context, state),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRemoteFallback(BuildContext context, String displayName, CallsState state) {
    return Container(
      color: const Color(0xFF14141E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 54,
              backgroundColor: Colors.white12,
              backgroundImage: widget.opponentAvatarUrl != null
                  ? NetworkImage(widget.opponentAvatarUrl!)
                  : null,
              child: widget.opponentAvatarUrl == null
                  ? Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (state.status == CallsStatus.ringingOutgoing)
              const Text('Ringing...', style: TextStyle(color: Colors.white70, fontSize: 14))
            else
              const Text(
                'Camera is turned off',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, CallsState state) {
    if (state.status == CallsStatus.ringingOutgoing) {
      return const Text('Calling...', style: TextStyle(color: Colors.white70, fontSize: 13));
    }
    if (state.status == CallsStatus.active) {
      if (state.rtcConnectionState == RtcConnectionState.connected) {
        return Text(
          _formatDuration(_elapsedSeconds),
          style: const TextStyle(
            color: Colors.greenAccent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        );
      } else if (state.rtcConnectionState == RtcConnectionState.connecting) {
        return const Text('Connecting...', style: TextStyle(color: Colors.white70, fontSize: 13));
      } else if (state.rtcConnectionState == RtcConnectionState.reconnecting) {
        return const Text(
          'Reconnecting...',
          style: TextStyle(color: Colors.amberAccent, fontSize: 13),
        );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildLocalPip(BuildContext context, CallsState state, String localUserId) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF222233),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: state.isCameraEnabled
          ? RtcVideoView(participantId: localUserId, isLocal: true, mirror: true, fit: BoxFit.cover)
          : Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_off, color: Colors.white54, size: 28),
                    SizedBox(height: 4),
                    Text('Camera off', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildControlsBar(BuildContext context, CallsState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Mic toggle
        IconButton.filledTonal(
          iconSize: 28,
          padding: const EdgeInsets.all(14),
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

        // Camera toggle
        IconButton.filledTonal(
          iconSize: 28,
          padding: const EdgeInsets.all(14),
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

        // Switch camera
        IconButton.filledTonal(
          iconSize: 28,
          padding: const EdgeInsets.all(14),
          style: IconButton.styleFrom(backgroundColor: Colors.white24),
          icon: const Icon(Icons.cameraswitch, color: Colors.white),
          tooltip: 'Switch Camera',
          onPressed: state.isCameraEnabled
              ? () {
                  context.read<CallsBloc>().add(const SwitchCameraRequested());
                }
              : null,
        ),

        // End Call FAB
        FloatingActionButton(
          heroTag: 'video_call_end_btn',
          backgroundColor: Colors.redAccent,
          elevation: 4,
          onPressed: _onEndCallPressed,
          child: const Icon(Icons.call_end, color: Colors.white, size: 28),
        ),
      ],
    );
  }
}
