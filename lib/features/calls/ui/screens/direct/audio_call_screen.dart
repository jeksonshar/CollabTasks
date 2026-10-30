import 'dart:async';

import 'package:collab_tasks/features/calls/domain/models/call_error_type.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_connection_state.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_bloc.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_event.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_state.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncCallTimer(context.read<CallsBloc>().state);
  }

  void _syncCallTimer(CallsState state) {
    if (state.status == CallsStatus.active &&
        state.rtcConnectionState == RtcConnectionState.connected) {
      _startTimerIfNeeded();
    } else if (state.status != CallsStatus.active) {
      _stopTimer();
    }
  }

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
    final activeCallId = context.read<CallsBloc>().state.activeCall?.id ?? widget.callId;
    context.read<CallsBloc>().add(EndCallRequested(callId: activeCallId));
  }

  String _resolveCallError(CallsState state, AppLocalizations l) {
    return switch (state.errorType) {
      CallErrorType.permissionDeniedVideo => l.callErrorPermissionDeniedVideo,
      CallErrorType.permissionDeniedAudio => l.callErrorPermissionDeniedAudio,
      CallErrorType.userUnavailable => l.callErrorUserUnavailable,
      CallErrorType.callTimeout => l.callErrorTimeout,
      CallErrorType.inviteFailed => l.callErrorInviteFailed,
      CallErrorType.rtcConnectionFailed => l.callErrorRtcFailed,
      CallErrorType.networkError => l.callErrorNetwork,
      CallErrorType.callNotFound => l.callErrorCallNotFound,
      CallErrorType.unknown || null => state.errorMessage ?? l.callErrorUnknown,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localization = AppLocalizations.of(context)!;
    final displayName = widget.opponentName ?? localization.callUserFallback;

    return BlocConsumer<CallsBloc, CallsState>(
      listenWhen: (previous, current) =>
          (previous.status != current.status &&
              (current.status == CallsStatus.idle || current.status == CallsStatus.error)) ||
          (current.status == CallsStatus.active &&
              (previous.status != CallsStatus.active ||
                  previous.rtcConnectionState != current.rtcConnectionState)) ||
          (current.status == CallsStatus.active &&
              current.errorType != null &&
              previous.errorType != current.errorType),
      listener: (context, state) {
        _syncCallTimer(state);

        // Auto pop when call returns to idle or terminated
        if (state.status == CallsStatus.idle || state.status == CallsStatus.error) {
          Navigator.of(context).pop();
        } else if (state.errorType != null && state.status == CallsStatus.active) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text(_resolveCallError(state, localization)),
                backgroundColor: theme.colorScheme.error,
                duration: const Duration(seconds: 3),
              ),
            );
        }
      },
      builder: (context, state) {
        final isRemoteSpeaking = state.participantMediaStates.any(
          (p) => !p.isLocal && p.isSpeaking,
        );

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
            backgroundColor: theme.colorScheme.surface,
            body: Stack(
              children: [
                // Avatar + opponent name + Call status & connection state
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isLandscape = constraints.maxWidth > constraints.maxHeight;
                      final avatarRadius = isLandscape ? 36.0 : 56.0;
                      final avatar = Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isRemoteSpeaking ? Colors.green : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: widget.opponentAvatarUrl != null
                              ? NetworkImage(widget.opponentAvatarUrl!)
                              : null,
                          child: widget.opponentAvatarUrl == null
                              ? Text(
                                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontSize: avatarRadius * 0.72,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                )
                              : null,
                        ),
                      );
                      final opponentName = Text(
                        displayName,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        maxLines: isLandscape ? 2 : null,
                        overflow: isLandscape ? TextOverflow.ellipsis : null,
                      );
                      final status = _buildStatusIndicator(context, state, localization);
                      final callInfo = isLandscape
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                avatar,
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [opponentName, const SizedBox(height: 8), status],
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                avatar,
                                const SizedBox(height: 24),
                                opponentName,
                                const SizedBox(height: 12),
                                status,
                              ],
                            );

                      return Padding(
                        // Reserve space for the bottom control bar and its safe area.
                        padding: EdgeInsets.only(bottom: isLandscape ? 168 : 184),
                        child: SafeArea(child: Center(child: callInfo)),
                      );
                    },
                  ),
                ),
                // Bottom controls bar
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
                      child: _buildControlsBar(context, state, localization),
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

  Widget _buildStatusIndicator(
    BuildContext context,
    CallsState state,
    AppLocalizations localization,
  ) {
    final theme = Theme.of(context);

    if (state.status == CallsStatus.ringingOutgoing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 8),
          Text(
            localization.callStatusCalling,
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      );
    }

    if (state.status == CallsStatus.active) {
      switch (state.rtcConnectionState) {
        case RtcConnectionState.connecting:
          return Text(
            localization.callStatusConnectingAudio,
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
              Text(
                localization.callStatusConnected,
                style: const TextStyle(fontSize: 12, color: Colors.green),
              ),
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
                localization.callStatusReconnecting,
                style: theme.textTheme.titleMedium?.copyWith(color: Colors.amber[800]),
              ),
            ],
          );
        case RtcConnectionState.failed:
          return Text(
            localization.callStatusConnectionFailed,
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error),
          );
        case RtcConnectionState.disconnected:
          return Text(
            localization.callStatusDisconnected,
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          );
      }
    }

    if (state.status == CallsStatus.terminating) {
      return Text(
        localization.callStatusEnding,
        style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildControlsBar(BuildContext context, CallsState state, AppLocalizations localization) {
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
          tooltip: state.isMicrophoneMuted
              ? localization.callActionUnmuteMic
              : localization.callActionMuteMic,
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
          icon: Icon(state.isSpeakerEnabled ? Icons.volume_up : Icons.phone),
          tooltip: localization.callActionSpeaker,
          onPressed: () {
            context.read<CallsBloc>().add(const ToggleSpeakerRequested());
          },
        ),
      ],
    );
  }
}
