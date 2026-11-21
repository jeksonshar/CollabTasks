import 'package:collab_tasks/features/calls/ui/widgets/rtc_video_view.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class CallPictureInPicture extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final String? remoteParticipantId;
  final bool isVideo;
  final bool isGroup;
  final bool isMicrophoneMuted;
  final VoidCallback onRestore;
  final VoidCallback onToggleMicrophone;
  final VoidCallback onEndOrLeave;

  const CallPictureInPicture({
    super.key,
    required this.displayName,
    required this.isVideo,
    required this.isGroup,
    required this.isMicrophoneMuted,
    required this.onRestore,
    required this.onToggleMicrophone,
    required this.onEndOrLeave,
    this.avatarUrl,
    this.remoteParticipantId,
  });

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
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
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    onPressed: onRestore,
                    tooltip: localization.callActionRestoreCall,
                    color: Colors.white,
                    icon: const Icon(Icons.open_in_full),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                  ),
                  IconButton(
                    onPressed: onToggleMicrophone,
                    tooltip: isMicrophoneMuted
                        ? localization.callActionUnmuteMic
                        : localization.callActionMuteMic,
                    color: isMicrophoneMuted ? Colors.redAccent : Colors.white,
                    icon: Icon(isMicrophoneMuted ? Icons.mic_off : Icons.mic),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                  ),
                  IconButton.filled(
                    onPressed: onEndOrLeave,
                    tooltip: isGroup
                        ? localization.callActionLeaveCall
                        : localization.callActionEndCall,
                    style: IconButton.styleFrom(backgroundColor: Colors.redAccent),
                    color: Colors.white,
                    icon: const Icon(Icons.call_end),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
