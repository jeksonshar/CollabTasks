import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:collab_tasks/features/calls/data/remote/agora/agora_uid_mapper.dart';
import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_connection_state.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_participant_media_state.dart';
import 'package:collab_tasks/features/calls/domain/services/rtc_service.dart';
import 'package:flutter/foundation.dart';

class AgoraRtcService implements RtcService {
  final String appId;
  final AgoraUidMapper _uidMapper;

  RtcEngine? _engine;
  final bool _isCustomEngine;

  final _connectionStateController = StreamController<RtcConnectionState>.broadcast();
  final _participantMediaStatesController =
      StreamController<List<RtcParticipantMediaState>>.broadcast();

  RtcConnectionState _currentState = RtcConnectionState.disconnected;
  final Map<String, RtcParticipantMediaState> _participants = {};

  CallSession? _activeSession;
  String? _activeLocalParticipantId;
  bool _isMicrophoneMuted = false;
  bool _isCameraEnabled = false;
  bool _isSpeakerEnabled = false;
  bool _isDisposed = false;

  AgoraRtcService({required this.appId, AgoraUidMapper? uidMapper, RtcEngine? engine})
    : _uidMapper = uidMapper ?? AgoraUidMapper(),
      _engine = engine,
      _isCustomEngine = engine != null;

  @override
  RtcConnectionState get currentConnectionState => _currentState;

  /// Expose engine reference within the Agora data package boundary.
  RtcEngine? get engine => _engine;

  /// Expose UID mapper within the Agora data package boundary.
  AgoraUidMapper get uidMapper => _uidMapper;

  /// Expose active session reference.
  CallSession? get activeSession => _activeSession;

  @visibleForTesting
  bool get isMicrophoneMuted => _isMicrophoneMuted;

  @visibleForTesting
  bool get isCameraEnabled => _isCameraEnabled;

  @visibleForTesting
  bool get isSpeakerEnabled => _isSpeakerEnabled;

  @override
  Stream<RtcConnectionState> get connectionStateStream => _connectionStateController.stream;

  @override
  List<RtcParticipantMediaState> get currentParticipantMediaStates => _participants.values.toList();

  @override
  Stream<List<RtcParticipantMediaState>> get participantMediaStatesStream =>
      _participantMediaStatesController.stream;

  Future<void> _ensureInitialized() async {
    if (_engine != null) return;

    final engine = createAgoraRtcEngine();
    await engine.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    _setupEventHandlers(engine);
    _engine = engine;
  }

  void _setupEventHandlers(RtcEngine engine) {
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('[AgoraRtcService] Joined channel: ${connection.channelId}');
          if (_activeSession?.roomId != connection.channelId) {
            debugPrint(
              '[AgoraRtcService] Ignoring join callback for stale channel ${connection.channelId}',
            );
            return;
          }
          _updateConnectionState(RtcConnectionState.connected);
          unawaited(_applySpeakerphoneRoute());
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint('[AgoraRtcService] Left channel: ${connection.channelId}');
          _updateConnectionState(RtcConnectionState.disconnected);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('[AgoraRtcService] Remote user joined: $remoteUid');
          final participantId = _uidMapper.toUserId(remoteUid) ?? 'user_$remoteUid';
          final isCallVideo = _activeSession?.extra['mediaType'] == 'video';
          _participants[participantId] = RtcParticipantMediaState(
            participantId: participantId,
            isLocal: false,
            isAudioMuted: false,
            isVideoEnabled: isCallVideo,
          );
          _emitParticipants();
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint('[AgoraRtcService] Remote user offline: $remoteUid, reason: $reason');
          final participantId = _uidMapper.toUserId(remoteUid) ?? 'user_$remoteUid';
          _participants.remove(participantId);
          _emitParticipants();
        },
        onConnectionStateChanged:
            (
              RtcConnection connection,
              ConnectionStateType state,
              ConnectionChangedReasonType reason,
            ) {
              debugPrint('[AgoraRtcService] Connection state: $state, reason: $reason');
              final mappedState = _mapAgoraConnectionState(state);
              _updateConnectionState(mappedState);
            },
        onUserMuteAudio: (RtcConnection connection, int remoteUid, bool muted) {
          final participantId = _uidMapper.toUserId(remoteUid) ?? 'user_$remoteUid';
          final existing = _participants[participantId];
          if (existing != null) {
            _participants[participantId] = existing.copyWith(isAudioMuted: muted);
            _emitParticipants();
          }
        },
        onUserMuteVideo: (RtcConnection connection, int remoteUid, bool muted) {
          final participantId = _uidMapper.toUserId(remoteUid) ?? 'user_$remoteUid';
          final existing = _participants[participantId];
          if (existing != null) {
            _participants[participantId] = existing.copyWith(isVideoEnabled: !muted);
            _emitParticipants();
          }
        },
        onRemoteVideoStateChanged:
            (
              RtcConnection connection,
              int remoteUid,
              RemoteVideoState state,
              RemoteVideoStateReason reason,
              int elapsed,
            ) {
              debugPrint(
                '[AgoraRtcService] Remote video state changed: uid=$remoteUid, state=$state, reason=$reason',
              );
              final participantId = _uidMapper.toUserId(remoteUid) ?? 'user_$remoteUid';
              final isVideo =
                  state == RemoteVideoState.remoteVideoStateDecoding ||
                  state == RemoteVideoState.remoteVideoStateStarting;
              final existing = _participants[participantId];
              if (existing != null) {
                _participants[participantId] = existing.copyWith(isVideoEnabled: isVideo);
              } else {
                _participants[participantId] = RtcParticipantMediaState(
                  participantId: participantId,
                  isLocal: false,
                  isAudioMuted: false,
                  isVideoEnabled: isVideo,
                );
              }
              _emitParticipants();
            },
        onFirstRemoteVideoDecoded:
            (RtcConnection connection, int remoteUid, int width, int height, int elapsed) {
              debugPrint(
                '[AgoraRtcService] First remote video decoded: uid=$remoteUid ($width x $height)',
              );
              final participantId = _uidMapper.toUserId(remoteUid) ?? 'user_$remoteUid';
              final existing = _participants[participantId];
              if (existing != null) {
                _participants[participantId] = existing.copyWith(isVideoEnabled: true);
              } else {
                _participants[participantId] = RtcParticipantMediaState(
                  participantId: participantId,
                  isLocal: false,
                  isAudioMuted: false,
                  isVideoEnabled: true,
                );
              }
              _emitParticipants();
            },
        onAudioVolumeIndication:
            (
              RtcConnection connection,
              List<AudioVolumeInfo> speakers,
              int totalVolume,
              int speakerNumber,
            ) {
              bool changed = false;
              final localUid = _activeSession != null
                  ? _uidMapper.toAgoraUid(_activeSession!.localUserId)
                  : null;

              for (final speaker in speakers) {
                final isLocal = (speaker.uid == 0) || (speaker.uid == localUid);
                final participantId = isLocal
                    ? (_activeLocalParticipantId ?? _activeSession?.localUserId ?? '')
                    : (_uidMapper.toUserId(speaker.uid ?? 0) ?? 'user_${speaker.uid}');

                if (participantId.isEmpty) continue;

                final existing = _participants[participantId];
                if (existing != null) {
                  final volume = (speaker.volume ?? 0) / 255.0;
                  final isSpeaking = volume > 0.1;
                  if (existing.isSpeaking != isSpeaking ||
                      (existing.audioLevel - volume).abs() > 0.05) {
                    _participants[participantId] = existing.copyWith(
                      isSpeaking: isSpeaking,
                      audioLevel: volume,
                    );
                    changed = true;
                  }
                }
              }

              if (changed) {
                _emitParticipants();
              }
            },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('[AgoraRtcService] Error: $err, msg: $msg');
          if (err == ErrorCodeType.errJoinChannelRejected ||
              err == ErrorCodeType.errTokenExpired ||
              err == ErrorCodeType.errInvalidToken) {
            leaveSession();
            _updateConnectionState(RtcConnectionState.failed);
          }
        },
      ),
    );
  }

  RtcConnectionState _mapAgoraConnectionState(ConnectionStateType state) {
    switch (state) {
      case ConnectionStateType.connectionStateConnecting:
        return RtcConnectionState.connecting;
      case ConnectionStateType.connectionStateConnected:
        return RtcConnectionState.connected;
      case ConnectionStateType.connectionStateReconnecting:
        return RtcConnectionState.reconnecting;
      case ConnectionStateType.connectionStateDisconnected:
        return RtcConnectionState.disconnected;
      case ConnectionStateType.connectionStateFailed:
        return RtcConnectionState.failed;
    }
  }

  void _updateConnectionState(RtcConnectionState state) {
    _currentState = state;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }

  void _emitParticipants() {
    if (!_participantMediaStatesController.isClosed) {
      _participantMediaStatesController.add(_participants.values.toList());
    }
  }

  @override
  Future<void> joinSession(CallSession session) async {
    if (_isDisposed) {
      throw StateError('Cannot join session on a disposed AgoraRtcService');
    }

    await _ensureInitialized();

    // Start every call with clean media and route state. Settings from the
    // previous channel must not leak into the next call.
    final isVideo = session.extra['mediaType'] == 'video';
    _isMicrophoneMuted = false;
    _isCameraEnabled = isVideo;
    _isSpeakerEnabled = false;
    _participants.clear();
    _activeSession = session;

    _updateConnectionState(RtcConnectionState.connecting);

    // Audio setup
    await _engine!.enableAudio();
    await _engine!.enableAudioVolumeIndication(interval: 200, smooth: 3, reportVad: true);
    await _engine!.muteLocalAudioStream(false);
    await _engine!.setDefaultAudioRouteToSpeakerphone(false);

    // Explicitly disable video for audio calls so a previous session cannot
    // leave its camera enabled or published.
    if (isVideo) {
      await _engine!.enableVideo();
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 360),
          frameRate: 15,
          bitrate: 600,
        ),
      );
      await _engine!.startPreview();
    } else {
      await _engine!.stopPreview();
      await _engine!.disableVideo();
    }

    final rawParticipants = session.extra['participants'];
    final rawCanonicalIds = session.extra['participantCanonicalIds'];
    if (rawParticipants is Map && rawCanonicalIds is Map) {
      _uidMapper.restoreCallMapping(rawParticipants, rawCanonicalIds);
    } else {
      _uidMapper.mapCallParticipants([session.localUserId]);
    }

    // The repository sent this same stable UID to the token function. Verify
    // that the session mapping still resolves to it before joining Agora.
    final localUid = _uidMapper.toAgoraUid(session.localUserId);
    final extraUid = session.extra['uid'];
    if (extraUid is num && extraUid.toInt() != localUid) {
      throw StateError(
        'Agora session UID $extraUid does not match stable UID $localUid for ${session.localUserId}',
      );
    }
    debugPrint('[AgoraRtcService] joinSession: channelId=${session.roomId}, uid=$localUid');

    // Add local participant
    _activeLocalParticipantId = _uidMapper.canonicalIdentity(session.localUserId);
    _participants[_activeLocalParticipantId!] = RtcParticipantMediaState(
      participantId: _activeLocalParticipantId!,
      isLocal: true,
      isAudioMuted: _isMicrophoneMuted,
      isSpeaking: _isSpeakerEnabled,
      isVideoEnabled: _isCameraEnabled,
    );
    _emitParticipants();

    await _engine!.joinChannel(
      token: session.token,
      channelId: session.roomId,
      uid: localUid,
      options: ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        publishCameraTrack: isVideo,
        autoSubscribeVideo: isVideo,
      ),
    );
  }

  @override
  Future<void> leaveSession() async {
    final engine = _engine;
    if (engine != null) {
      final wasConnected =
          _currentState == RtcConnectionState.connected ||
          _currentState == RtcConnectionState.reconnecting;
      // Each SDK cleanup is isolated so one failed operation cannot prevent
      // the remaining controls from being reset.
      await _tryReset('stopPreview', engine.stopPreview, const Duration(seconds: 3));
      await _tryReset(
        'muteLocalAudioStream',
        () => engine.muteLocalAudioStream(false),
        const Duration(seconds: 3),
      );
      await _tryReset(
        'setDefaultAudioRouteToSpeakerphone',
        () => engine.setDefaultAudioRouteToSpeakerphone(false),
        const Duration(seconds: 3),
      );
      if (wasConnected) {
        await _tryReset(
          'setEnableSpeakerphone',
          () => engine.setEnableSpeakerphone(false),
          const Duration(seconds: 3),
        );
      }
      await _tryReset('leaveChannel', engine.leaveChannel, const Duration(seconds: 5));
      await _tryReset('disableVideo', engine.disableVideo, const Duration(seconds: 3));
      await _tryReset('disableAudio', engine.disableAudio, const Duration(seconds: 3));
    }
    _activeSession = null;
    _activeLocalParticipantId = null;
    _isMicrophoneMuted = false;
    _isCameraEnabled = false;
    _isSpeakerEnabled = false;
    _participants.clear();
    _uidMapper.clear();
    _emitParticipants();
    _updateConnectionState(RtcConnectionState.disconnected);
  }

  Future<void> _tryReset(String operation, Future<void> Function() reset, Duration timeout) async {
    try {
      await reset().timeout(
        timeout,
        onTimeout: () => debugPrint('[AgoraRtcService] $operation timed out during cleanup'),
      );
    } catch (error) {
      debugPrint('[AgoraRtcService] Failed to reset $operation: $error');
    }
  }

  @override
  Future<void> setMicrophoneMuted(bool muted) async {
    if (_engine != null) {
      await _engine!.muteLocalAudioStream(muted);
    }
    _isMicrophoneMuted = muted;
    final localId = _activeLocalParticipantId;
    if (localId != null && _participants.containsKey(localId)) {
      _participants[localId] = _participants[localId]!.copyWith(isAudioMuted: muted);
      _emitParticipants();
    }
  }

  @override
  Future<void> setCameraEnabled(bool enabled) async {
    if (_engine != null) {
      if (enabled) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
        await _engine!.updateChannelMediaOptions(
          const ChannelMediaOptions(publishCameraTrack: true),
        );
      } else {
        await _engine!.stopPreview();
        await _engine!.disableVideo();
        await _engine!.updateChannelMediaOptions(
          const ChannelMediaOptions(publishCameraTrack: false),
        );
      }
    }
    _isCameraEnabled = enabled;
    final localId = _activeLocalParticipantId;
    if (localId != null && _participants.containsKey(localId)) {
      _participants[localId] = _participants[localId]!.copyWith(isVideoEnabled: enabled);
      _emitParticipants();
    }
  }

  @override
  Future<void> setSpeakerEnabled(bool enabled) async {
    if (_engine != null) {
      await _engine!.setDefaultAudioRouteToSpeakerphone(enabled);
      if (_currentState == RtcConnectionState.connected ||
          _currentState == RtcConnectionState.reconnecting) {
        await _engine!.setEnableSpeakerphone(enabled);
      }
    }
    _isSpeakerEnabled = enabled;
  }

  Future<void> _applySpeakerphoneRoute() async {
    final engine = _engine;
    if (engine == null || _activeSession == null) return;
    try {
      await engine.setEnableSpeakerphone(_isSpeakerEnabled);
    } catch (error) {
      debugPrint('[AgoraRtcService] Failed to apply speakerphone route: $error');
    }
  }

  @override
  Future<void> switchCamera() async {
    if (_engine != null) {
      await _engine!.switchCamera();
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    await leaveSession();

    if (!_isCustomEngine && _engine != null) {
      await _engine!.release();
      _engine = null;
    }

    _uidMapper.clear();
    await _connectionStateController.close();
    await _participantMediaStatesController.close();
  }
}
