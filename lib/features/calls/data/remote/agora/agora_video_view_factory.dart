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
      return _AgoraVideoViewWidget(
        key: key ?? const ValueKey('agora_video_local'),
        engine: engine,
        isLocal: true,
        uid: 0,
        channelId: '',
        renderMode: renderMode,
        mirror: mirror,
      );
    } else {
      final uid = _agoraRtcService.uidMapper.toAgoraUid(participantId);
      final channelId = _agoraRtcService.activeSession?.roomId ?? '';

      return _AgoraVideoViewWidget(
        key: key ?? ValueKey('agora_video_remote_$participantId'),
        engine: engine,
        isLocal: false,
        uid: uid,
        channelId: channelId,
        renderMode: renderMode,
        mirror: false,
      );
    }
  }
}

class _AgoraVideoViewWidget extends StatefulWidget {
  final RtcEngine engine;
  final bool isLocal;
  final int uid;
  final String channelId;
  final RenderModeType renderMode;
  final bool mirror;

  const _AgoraVideoViewWidget({
    super.key,
    required this.engine,
    required this.isLocal,
    required this.uid,
    required this.channelId,
    required this.renderMode,
    required this.mirror,
  });

  @override
  State<_AgoraVideoViewWidget> createState() => _AgoraVideoViewWidgetState();
}

class _AgoraVideoViewWidgetState extends State<_AgoraVideoViewWidget> {
  VideoViewControllerBase? _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant _AgoraVideoViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.engine != widget.engine ||
        oldWidget.isLocal != widget.isLocal ||
        oldWidget.uid != widget.uid ||
        oldWidget.channelId != widget.channelId ||
        oldWidget.renderMode != widget.renderMode ||
        oldWidget.mirror != widget.mirror) {
      _controller?.dispose();
      _initController();
    }
  }

  void _initController() {
    if (widget.isLocal) {
      _controller = VideoViewController(
        rtcEngine: widget.engine,
        canvas: VideoCanvas(
          uid: 0,
          renderMode: widget.renderMode,
          mirrorMode: widget.mirror
              ? VideoMirrorModeType.videoMirrorModeEnabled
              : VideoMirrorModeType.videoMirrorModeDisabled,
        ),
      );
    } else {
      _controller = VideoViewController.remote(
        rtcEngine: widget.engine,
        canvas: VideoCanvas(uid: widget.uid, renderMode: widget.renderMode),
        connection: RtcConnection(channelId: widget.channelId),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }
    return AgoraVideoView(controller: controller);
  }
}
