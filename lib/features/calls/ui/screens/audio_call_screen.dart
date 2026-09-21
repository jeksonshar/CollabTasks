import 'dart:async';

import 'package:collab_tasks/features/calls/domain/models/rtc_connection_state.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_bloc.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_event.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AudioCallScreen extends StatefulWidget {
  final String callId;
  final String? opponentName;
  final String? opponentAvatarUrl;

  const AudioCallScreen({
    super.key,
    required this.callId,
    this.opponentName,
    this.opponentAvatarUrl,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  Timer? _durationTimer;
  int _elapsedSeconds = 0;

  @override
  void dispose() {
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
    context.read<CallsBloc>().add(EndCallRequested(callId: widget.callId));
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

        // Auto pop when call returns to idle or terminated
        if (state.status == CallsStatus.idle) {
          Navigator.of(context).maybePop();
        } else if (state.status == CallsStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Call failed'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
          Navigator.of(context).maybePop();
        }
      },
      builder: (context, state) {
        final isRemoteSpeaking = state.participantMediaStates.any(
          (p) => !p.isLocal && p.isSpeaking,
        );

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              _onEndCallPressed();
            }
          },
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'End Call',
                  onPressed: _onEndCallPressed,
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  // Avatar with speaking indicator ring
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isRemoteSpeaking ? Colors.green : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: widget.opponentAvatarUrl != null
                            ? NetworkImage(widget.opponentAvatarUrl!)
                            : null,
                        child: widget.opponentAvatarUrl == null
                            ? Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Opponent Name
                  Text(
                    displayName,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Call status & connection state
                  _buildStatusIndicator(context, state),
                  const Spacer(flex: 2),
                  // Bottom controls bar
                  _buildControlsBar(context, state),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(BuildContext context, CallsState state) {
    final theme = Theme.of(context);

    if (state.status == CallsStatus.ringingOutgoing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 8),
          Text(
            'Calling...',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      );
    }

    if (state.status == CallsStatus.active) {
      switch (state.rtcConnectionState) {
        case RtcConnectionState.connecting:
          return Text(
            'Connecting audio...',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          );
        case RtcConnectionState.connected:
          return Column(
            children: [
              Text(
                _formatDuration(_elapsedSeconds),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              const Text('Connected', style: TextStyle(fontSize: 12, color: Colors.green)),
            ],
          );
        case RtcConnectionState.reconnecting:
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
              ),
              const SizedBox(width: 8),
              Text(
                'Reconnecting...',
                style: theme.textTheme.titleMedium?.copyWith(color: Colors.amber[800]),
              ),
            ],
          );
        case RtcConnectionState.failed:
          return Text(
            'Connection failed',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error),
          );
        case RtcConnectionState.disconnected:
          return Text(
            'Disconnected',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          );
      }
    }

    if (state.status == CallsStatus.terminating) {
      return Text(
        'Ending call...',
        style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildControlsBar(BuildContext context, CallsState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Mic mute toggle
        IconButton.filledTonal(
          iconSize: 32,
          padding: const EdgeInsets.all(16),
          style: IconButton.styleFrom(
            backgroundColor: state.isMicrophoneMuted ? Colors.red.withValues(alpha: 0.2) : null,
          ),
          icon: Icon(
            state.isMicrophoneMuted ? Icons.mic_off : Icons.mic,
            color: state.isMicrophoneMuted ? Colors.red : null,
          ),
          tooltip: state.isMicrophoneMuted ? 'Unmute Mic' : 'Mute Mic',
          onPressed: () {
            context.read<CallsBloc>().add(const ToggleMicrophoneRequested());
          },
        ),
        // End Call button
        FloatingActionButton.large(
          heroTag: 'end_call_large_btn',
          backgroundColor: Colors.redAccent,
          elevation: 4,
          onPressed: _onEndCallPressed,
          child: const Icon(Icons.call_end, color: Colors.white, size: 38),
        ),
        // Audio output / speaker placeholder
        IconButton.filledTonal(
          iconSize: 32,
          padding: const EdgeInsets.all(16),
          icon: const Icon(Icons.volume_up),
          tooltip: 'Speaker',
          onPressed: () {
            // Volume / audio output route toggle
          },
        ),
      ],
    );
  }
}
