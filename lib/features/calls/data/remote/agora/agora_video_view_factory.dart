import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:collab_tasks/features/calls/data/remote/agora/agora_rtc_service.dart';
import 'package:collab_tasks/features/calls/ui/widgets/rtc_video_view.dart';
import 'package:flutter/material.dart';

/// Agora-specific implementation of [RtcVideoViewFactory].
/// Isolated strictly inside the Agora integration boundary.
class AgoraVideoViewFactory implements RtcVideoViewFactory {
  final AgoraRtcService _agoraRtcService;

  const AgoraVideoViewFactory(this._agoraRtcService);

  @override
  Widget buildVideoView({
    Key? key,
    required String participantId,
    required bool isLocal,
    BoxFit fit = BoxFit.cover,
    bool mirror = false,
  }) {
    final engine = _agoraRtcService.engine;
    if (engine == null) {
      return Container(
        key: key,
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
      );
    }

    final renderMode = fit == BoxFit.cover
        ? RenderModeType.renderModeHidden
        : RenderModeType.renderModeFit;

    if (isLocal) {
      return AgoraVideoView(
        key: key ?? const ValueKey('agora_video_local'),
        controller: VideoViewController(
          rtcEngine: engine,
          canvas: VideoCanvas(
            uid: 0,
            renderMode: renderMode,
            mirrorMode: mirror
                ? VideoMirrorModeType.videoMirrorModeEnabled
                : VideoMirrorModeType.videoMirrorModeDisabled,
          ),
        ),
      );
    } else {
      final uid = _agoraRtcService.uidMapper.toAgoraUid(participantId);
      final channelId = _agoraRtcService.activeSession?.roomId ?? '';

      return AgoraVideoView(
        key: key ?? ValueKey('agora_video_remote_$participantId'),
        controller: VideoViewController.remote(
          rtcEngine: engine,
          canvas: VideoCanvas(uid: uid, renderMode: renderMode),
          connection: RtcConnection(channelId: channelId),
        ),
      );
    }
  }
}
