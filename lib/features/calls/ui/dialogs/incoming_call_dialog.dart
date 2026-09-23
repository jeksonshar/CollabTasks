import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_bloc.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_event.dart';
import 'package:collab_tasks/features/calls/ui/blocs/calls_state.dart';
import 'package:collab_tasks/features/calls/ui/screens/audio_call_screen.dart';
import 'package:collab_tasks/features/calls/ui/screens/group_call_screen.dart';
import 'package:collab_tasks/features/calls/ui/screens/video_call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class IncomingCallDialog extends StatelessWidget {
  final Call call;
  final String currentUserId;

  const IncomingCallDialog({super.key, required this.call, required this.currentUserId});

  static Future<void> show(
    BuildContext context, {
    required Call call,
    required String currentUserId,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => IncomingCallDialog(call: call, currentUserId: currentUserId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<CallsBloc, CallsState>(
      // Only fire when transitioning OUT of ringingIncoming to avoid
      // spurious pops triggered by unrelated state changes (e.g. mic toggle).
      listenWhen: (prev, curr) =>
          prev.status == CallsStatus.ringingIncoming && curr.status != CallsStatus.ringingIncoming,
      listener: (context, state) {
        // Caller cancelled / call ended / rejected → close the dialog.
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) nav.pop();
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            // Reject on back gesture
            context.read<CallsBloc>().add(
              RejectCallRequested(callId: call.id, userId: currentUserId),
            );
          }
        },
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: call.callerAvatarUrl != null
                    ? NetworkImage(call.callerAvatarUrl!)
                    : null,
                child: call.callerAvatarUrl == null
                    ? Text(
                        call.callerName.isNotEmpty ? call.callerName[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                call.callerName,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    call.isGroup
                        ? Icons.groups
                        : (call.type == CallType.video ? Icons.videocam : Icons.call),
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    call.isGroup
                        ? 'Incoming group ${call.type.name} call...'
                        : 'Incoming ${call.type.name} call...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        heroTag: 'reject_call_btn',
                        elevation: 2,
                        backgroundColor: Colors.redAccent,
                        onPressed: () {
                          context.read<CallsBloc>().add(
                            RejectCallRequested(callId: call.id, userId: currentUserId),
                          );
                          // Listener will close the dialog via pop() once bloc emits non-ringing
                        },
                        child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 8),
                      const Text('Decline', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(width: 32),
                  // Accept button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        heroTag: 'accept_call_btn',
                        elevation: 2,
                        backgroundColor: Colors.green,
                        onPressed: () {
                          context.read<CallsBloc>().add(
                            AcceptCallRequested(callId: call.id, userId: currentUserId),
                          );
                          // Close dialog immediately; then push call screen.
                          // We do NOT rely on the listener here because the listener fires
                          // asynchronously (after the bloc emits), which could mean the
                          // dialog is still visible when the call screen is pushed.
                          Navigator.of(context, rootNavigator: true).pop();

                          if (call.isGroup) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GroupCallScreen(
                                  callId: call.id,
                                  groupName: call.callerName,
                                  callType: call.type,
                                ),
                              ),
                            );
                          } else if (call.type == CallType.video) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => VideoCallScreen(
                                  callId: call.id,
                                  opponentName: call.callerName,
                                  opponentAvatarUrl: call.callerAvatarUrl,
                                  opponentId: call.callerId,
                                ),
                              ),
                            );
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AudioCallScreen(
                                  callId: call.id,
                                  opponentName: call.callerName,
                                  opponentAvatarUrl: call.callerAvatarUrl,
                                ),
                              ),
                            );
                          }
                        },
                        child: Icon(
                          call.type == CallType.video ? Icons.videocam : Icons.call,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Accept', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
