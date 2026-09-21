import 'package:collab_tasks/features/calls/ui/widgets/rtc_video_view.dart';
import 'package:flutter/material.dart';

/// Fake implementation of [RtcVideoViewFactory] for headless tests,
/// mocks, and UI preview without native WebRTC / Agora engines.
class FakeVideoViewFactory implements RtcVideoViewFactory {
  const FakeVideoViewFactory();

  @override
  Widget buildVideoView({
    Key? key,
    required String participantId,
    required bool isLocal,
    BoxFit fit = BoxFit.cover,
    bool mirror = false,
  }) {
    return Container(
      key: key ?? ValueKey('fake_video_${isLocal ? "local" : participantId}'),
      color: const Color(0xFF1E1E2C),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isLocal ? Icons.videocam : Icons.person, color: Colors.white70, size: 36),
          const SizedBox(height: 6),
          Text(
            isLocal ? 'Local Preview' : 'Video: $participantId',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
