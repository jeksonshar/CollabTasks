import 'package:collab_tasks/features/calls/ui/widgets/rtc_video_view.dart';
import 'package:flutter/material.dart';

class CallPictureInPicture extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final String? remoteParticipantId;
  final bool isVideo;

  const CallPictureInPicture({
    super.key,
    required this.displayName,
    required this.isVideo,
    this.avatarUrl,
    this.remoteParticipantId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isVideo && remoteParticipantId != null && remoteParticipantId!.isNotEmpty)
            RtcVideoView(participantId: remoteParticipantId!, isLocal: false, fit: BoxFit.cover)
          else
            ColoredBox(
              color: const Color(0xFF20202B),
              child: Center(
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl!),
                  child: avatarUrl != null
                      ? null
                      : Text(
                          displayName.isEmpty ? '?' : displayName.characters.first.toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
