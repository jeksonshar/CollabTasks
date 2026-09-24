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

class IncomingCallDialog extends StatefulWidget {
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
  State<IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends State<IncomingCallDialog> {
  CallsBloc? _callsBloc;
  bool _didNotifyOpened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _callsBloc ??= context.read<CallsBloc>();
    if (!_didNotifyOpened) {
      _didNotifyOpened = true;
      _callsBloc!.add(IncomingCallDialogOpened(widget.call.id));
    }
  }

  @override
  void dispose() {
    // Do NOT send StopCallAlertRequested here.
    // Every dialog-close path (Reject, Accept, caller cancel, back gesture)
    // already triggers _cleanup() → _stopCallAlertSafely() inside CallsBloc
    // before or after the dialog is popped. An extra event here would cause a
    // guaranteed double-stop on every call termination.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<CallsBloc, CallsState>(
      // Only fire when caller cancelled (idle) or call errored (error).
      // NEVER fire when call becomes active (accepted) because the Accept
      // button itself handles closing the dialog and pushing the call screen.
      listenWhen: (prev, curr) =>
          prev.status == CallsStatus.ringingIncoming &&
          (curr.status == CallsStatus.idle || curr.status == CallsStatus.error),
      listener: (context, state) {
        // Caller cancelled / call ended / error → close the dialog.
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) nav.pop();
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            // Reject on back gesture
            context.read<CallsBloc>().add(
              RejectCallRequested(callId: widget.call.id, userId: widget.currentUserId),
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
                backgroundImage: widget.call.callerAvatarUrl != null
                    ? NetworkImage(widget.call.callerAvatarUrl!)
                    : null,
                child: widget.call.callerAvatarUrl == null
                    ? Text(
                        widget.call.callerName.isNotEmpty
                            ? widget.call.callerName[0].toUpperCase()
                            : '?',
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
                widget.call.callerName,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.call.isGroup
                        ? Icons.groups
                        : (widget.call.type == CallType.video ? Icons.videocam : Icons.call),
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.call.isGroup
                        ? 'Incoming group ${widget.call.type.name} call...'
                        : 'Incoming ${widget.call.type.name} call...',
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
                            RejectCallRequested(
                              callId: widget.call.id,
                              userId: widget.currentUserId,
                            ),
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
                            AcceptCallRequested(
                              callId: widget.call.id,
                              userId: widget.currentUserId,
                            ),
                          );
                          final route = widget.call.isGroup
                              ? MaterialPageRoute<void>(
                                  builder: (_) => GroupCallScreen(
                                    callId: widget.call.id,
                                    groupName: widget.call.callerName,
                                    callType: widget.call.type,
                                  ),
                                )
                              : (widget.call.type == CallType.video
                                    ? MaterialPageRoute<void>(
                                        builder: (_) => VideoCallScreen(
                                          callId: widget.call.id,
                                          opponentName: widget.call.callerName,
                                          opponentAvatarUrl: widget.call.callerAvatarUrl,
                                          opponentId: widget.call.callerId,
                                        ),
                                      )
                                    : MaterialPageRoute<void>(
                                        builder: (_) => AudioCallScreen(
                                          callId: widget.call.id,
                                          opponentName: widget.call.callerName,
                                          opponentAvatarUrl: widget.call.callerAvatarUrl,
                                        ),
                                      ));

                          Navigator.of(context, rootNavigator: true)
                            ..pop()
                            ..push(route);
                        },
                        child: Icon(
                          widget.call.type == CallType.video ? Icons.videocam : Icons.call,
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
