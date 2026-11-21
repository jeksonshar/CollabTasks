import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:collab_tasks/features/calls/data/remote/agora/agora_rtc_service.dart';
import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
import 'package:collab_tasks/features/calls/domain/services/rtc_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum CallPictureInPictureAction { restore, toggleMicrophone, endCall, leaveCall }

enum CallPictureInPictureEventType { modeChanged, action }

class CallPictureInPictureEvent {
  final CallPictureInPictureEventType type;
  final bool? isInPictureInPicture;
  final CallPictureInPictureAction? action;

  const CallPictureInPictureEvent._({required this.type, this.isInPictureInPicture, this.action});

  const CallPictureInPictureEvent.modeChanged(bool isInPictureInPicture)
    : this._(
        type: CallPictureInPictureEventType.modeChanged,
        isInPictureInPicture: isInPictureInPicture,
      );

  const CallPictureInPictureEvent.action(CallPictureInPictureAction action)
    : this._(type: CallPictureInPictureEventType.action, action: action);

  static CallPictureInPictureEvent? fromPlatformValue(Object? value) {
    if (value is! Map) return null;
    final type = value['type'];
    if (type == 'modeChanged' && value['isInPictureInPicture'] is bool) {
      return CallPictureInPictureEvent.modeChanged(value['isInPictureInPicture'] as bool);
    }
    if (type != 'action') return null;

    final action = switch (value['action']) {
      'restore' => CallPictureInPictureAction.restore,
      'toggleMicrophone' => CallPictureInPictureAction.toggleMicrophone,
      'endCall' => CallPictureInPictureAction.endCall,
      'leaveCall' => CallPictureInPictureAction.leaveCall,
      _ => null,
    };
    return action == null ? null : CallPictureInPictureEvent.action(action);
  }
}

class CallPictureInPictureConfiguration {
  final String callId;
  final String displayName;
  final String? avatarUrl;
  final String? remoteParticipantId;
  final bool isVideo;
  final bool isGroup;
  final CallSession? session;

  const CallPictureInPictureConfiguration({
    required this.callId,
    required this.displayName,
    required this.isVideo,
    required this.isGroup,
    this.avatarUrl,
    this.remoteParticipantId,
    this.session,
  });

  Map<String, Object?> toMap() => {
    'callId': callId,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'remoteParticipantId': remoteParticipantId,
    'isVideo': isVideo,
    'isGroup': isGroup,
  };
}

/// Owns Agora's PiP controller and the Android audio-call PiP bridge.
class CallPictureInPictureService {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.collab_tasks/call_picture_in_picture',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.collab_tasks/call_picture_in_picture/events',
  );

  final RtcService _rtcService;
  final TargetPlatform _platform;
  final MethodChannel _methods;
  final EventChannel _eventsChannel;
  final AgoraPipController? _injectedController;
  final StreamController<CallPictureInPictureEvent> _events =
      StreamController<CallPictureInPictureEvent>.broadcast();

  AgoraPipController? _controller;
  StreamSubscription<Object?>? _nativeEventSubscription;
  CallPictureInPictureConfiguration? _configuration;
  String? _preparedKey;
  bool _isPrepared = false;
  bool _observerRegistered = false;
  bool _autoEnterSupported = false;
  bool _nativeCallBackgroundServiceStarted = false;
  bool _closed = false;

  CallPictureInPictureService({
    required RtcService rtcService,
    AgoraPipController? controller,
    TargetPlatform? platform,
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  }) : _rtcService = rtcService,
       _injectedController = controller,
       _platform = platform ?? defaultTargetPlatform,
       _methods = methodChannel ?? _methodChannel,
       _eventsChannel = eventChannel ?? _eventChannel {
    if (_platform == TargetPlatform.android) {
      _nativeEventSubscription = _eventsChannel.receiveBroadcastStream().listen(
        _onNativeEvent,
        onError: (Object _) {},
      );
    }
  }

  Stream<CallPictureInPictureEvent> get events => _events.stream;

  Future<bool> prepare(CallPictureInPictureConfiguration configuration) async {
    if (_closed) return false;
    final preparationKey = [
      configuration.callId,
      configuration.isVideo,
      configuration.isGroup,
      configuration.remoteParticipantId ?? '',
    ].join('|');
    if (_isPrepared && _preparedKey == preparationKey) return true;
    _configuration = configuration;

    if (_platform == TargetPlatform.android &&
        !await _startAndroidCallBackgroundService(configuration)) {
      return false;
    }

    if (!configuration.isVideo) {
      if (_platform != TargetPlatform.android) return false;
      _preparedKey = preparationKey;
      _isPrepared = true;
      return true;
    }
    if (_platform != TargetPlatform.android && _platform != TargetPlatform.iOS) {
      return false;
    }

    final controller = await _ensureController();
    final session = configuration.session;
    if (controller == null || session == null || session.callId != configuration.callId) {
      return false;
    }

    try {
      if (!await controller.pipIsSupported()) return false;
      _autoEnterSupported = await controller.pipIsAutoEnterSupported();
      final options = _buildOptions(configuration, session);
      final configured = await controller.pipSetup(options);
      if (configured) {
        _preparedKey = preparationKey;
        _isPrepared = true;
      }
      return configured;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> enterPictureInPicture(CallPictureInPictureConfiguration configuration) async {
    if (!await prepare(configuration)) return false;

    if (!configuration.isVideo) {
      try {
        return await _methods.invokeMethod<bool>(
              'enterAudioPictureInPicture',
              configuration.toMap(),
            ) ??
            false;
      } on MissingPluginException {
        return false;
      } on PlatformException {
        return false;
      }
    }

    final controller = _controller;
    if (controller == null) return false;
    try {
      if (await controller.isPipActivated()) return true;
      if (_autoEnterSupported) return true;
      if (_platform == TargetPlatform.iOS) return false;
      return await controller.pipStart();
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> restoreCall() async {
    if (_platform == TargetPlatform.android) {
      try {
        await _methods.invokeMethod<void>('restoreCallActivity');
      } on MissingPluginException {
        // The system PiP restore control remains available if this bridge is absent.
      }
      return;
    }
    if (_configuration?.isVideo == true) {
      try {
        await _controller?.pipStop();
      } on PlatformException {
        // Native system controls remain available if restoring through Agora fails.
      }
      return;
    }
    try {
      await _methods.invokeMethod<void>('restoreAudioPictureInPicture');
    } on MissingPluginException {
      // A platform without audio PiP keeps the call active in the app.
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _nativeEventSubscription?.cancel();
    await _stopAndroidCallBackgroundService();
    final controller = _controller;
    if (controller != null) {
      if (_observerRegistered) {
        await controller.unregisterPipStateChangedObserver();
      }
      await controller.dispose();
    }
    await _events.close();
  }

  Future<AgoraPipController?> _ensureController() async {
    if (_controller != null) return _controller;
    final injectedController = _injectedController;
    if (injectedController != null) {
      _controller = injectedController;
    } else if (_rtcService is AgoraRtcService) {
      final engine = (_rtcService as AgoraRtcService).engine;
      if (engine != null) _controller = engine.createPipController();
    }
    final controller = _controller;
    if (controller == null || _observerRegistered) return controller;

    await controller.registerPipStateChangedObserver(
      AgoraPipStateChangedObserver(
        onPipStateChanged: (state, _) {
          if (!_events.isClosed) {
            _events.add(
              CallPictureInPictureEvent.modeChanged(state == AgoraPipState.pipStateStarted),
            );
          }
        },
      ),
    );
    _observerRegistered = true;
    return controller;
  }

  AgoraPipOptions _buildOptions(
    CallPictureInPictureConfiguration configuration,
    CallSession session,
  ) {
    if (_platform == TargetPlatform.android) {
      return AgoraPipOptions(
        autoEnterEnabled: _autoEnterSupported,
        aspectRatioX: 16,
        aspectRatioY: 9,
        seamlessResizeEnabled: true,
        useExternalStateMonitor: false,
      );
    }

    final agoraService = _rtcService as AgoraRtcService;
    final localUid = agoraService.uidMapper.toAgoraUid(session.localUserId);
    final remoteParticipantId = configuration.remoteParticipantId;
    final remoteUid = remoteParticipantId == null || remoteParticipantId.isEmpty
        ? null
        : agoraService.uidMapper.toAgoraUid(remoteParticipantId);
    final videoStreams = remoteUid == null
        ? const <AgoraPipVideoStream>[]
        : [
            AgoraPipVideoStream(
              connection: RtcConnection(channelId: session.roomId, localUid: localUid),
              canvas: VideoCanvas(
                uid: remoteUid,
                sourceType: VideoSourceType.videoSourceRemote,
                setupMode: VideoViewSetupMode.videoViewSetupAdd,
                renderMode: RenderModeType.renderModeHidden,
              ),
            ),
          ];
    return AgoraPipOptions(
      autoEnterEnabled: _autoEnterSupported,
      sourceContentView: 0,
      contentView: 0,
      preferredContentWidth: 1080,
      preferredContentHeight: 720,
      videoStreams: videoStreams,
      contentViewLayout: const AgoraPipContentViewLayout(row: 1, column: 1),
      controlStyle: 2,
    );
  }

  Future<bool> _configureNativeActions(CallPictureInPictureConfiguration configuration) async {
    try {
      return await _methods.invokeMethod<bool>('configureCallActions', {
            'isGroup': configuration.isGroup,
            'displayName': configuration.displayName,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> _startAndroidCallBackgroundService(
    CallPictureInPictureConfiguration configuration,
  ) async {
    try {
      if (!await _configureNativeActions(configuration)) return false;
      final started =
          await _methods.invokeMethod<bool>('startCallBackgroundService', {
            'displayName': configuration.displayName,
          }) ??
          false;
      _nativeCallBackgroundServiceStarted = started;
      return started;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> _stopAndroidCallBackgroundService() async {
    if (!_nativeCallBackgroundServiceStarted) return;
    _nativeCallBackgroundServiceStarted = false;
    try {
      await _methods.invokeMethod<void>('stopCallBackgroundService');
    } on MissingPluginException {
      // Process teardown releases the service if the native stop bridge is absent.
    } on PlatformException {
      // Service teardown must not prevent Agora controller cleanup.
    }
  }

  void _onNativeEvent(Object? value) {
    final event = CallPictureInPictureEvent.fromPlatformValue(value);
    if (event != null && !_events.isClosed) _events.add(event);
  }
}
