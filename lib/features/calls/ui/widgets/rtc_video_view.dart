import 'package:collab_tasks/di/service_locator.dart';
import 'package:flutter/material.dart';

/// Abstract factory interface for rendering RTC video tracks.
/// Provider-specific implementations (e.g. Agora, LiveKit, Fake) live in the data layer.
abstract class RtcVideoViewFactory {
  Widget buildVideoView({
    Key? key,
    required String participantId,
    required bool isLocal,
    BoxFit fit = BoxFit.cover,
    bool mirror = false,
  });
}

/// Provider-independent video view widget.
/// Resolves the concrete [RtcVideoViewFactory] from DI to render the video stream.
class RtcVideoView extends StatelessWidget {
  final String participantId;
  final bool isLocal;
  final BoxFit fit;
  final bool mirror;

  const RtcVideoView({
    super.key,
    required this.participantId,
    required this.isLocal,
    this.fit = BoxFit.cover,
    this.mirror = false,
  });

  @override
  Widget build(BuildContext context) {
    final factory = getIt<RtcVideoViewFactory>();
    return factory.buildVideoView(
      key: key,
      participantId: participantId,
      isLocal: isLocal,
      fit: fit,
      mirror: mirror,
    );
  }
}
