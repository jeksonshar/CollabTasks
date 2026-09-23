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
          _updateConnectionState(RtcConnectionState.connected);
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint('[AgoraRtcService] Left channel: ${connection.channelId}');
          _updateConnectionState(RtcConnectionState.disconnected);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('[AgoraRtcService] Remote user joined: $remoteUid');
          final participantId = _uidMapper.toUserId(remoteUid) ?? 'user_$remoteUid';
          _participants[participantId] = RtcParticipantMediaState(
            participantId: participantId,
            isLocal: false,
            isAudioMuted: false,
            isVideoEnabled: false,
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
            (RtcConnection connection,
            ConnectionStateType state,
            ConnectionChangedReasonType reason,) {
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
        onAudioVolumeIndication:
            (RtcConnection connection,
            List<AudioVolumeInfo> speakers,
            int totalVolume,
            int speakerNumber,) {
          bool changed = false;
          final localUid = _activeSession != null
              ? _uidMapper.toAgoraUid(_activeSession!.localUserId)
              : null;

          for (final speaker in speakers) {
            final isLocal = (speaker.uid == 0) || (speaker.uid == localUid);
            final participantId = isLocal
                ? (_activeSession?.localUserId ?? '')
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

    _activeSession = session;
    await _ensureInitialized();

    _updateConnectionState(RtcConnectionState.connecting);

    // Audio setup
    await _engine!.enableAudio();
    await _engine!.enableAudioVolumeIndication(interval: 200, smooth: 3, reportVad: true);

    // Video setup if video call or camera is enabled
    final isVideo = session.extra['mediaType'] == 'video' || _isCameraEnabled;
    if (isVideo) {
      await _engine!.enableVideo();
      await _engine!.startPreview();
      // await _engine!.setEnableSpeakerphone(true);
    }

    // Resolve local UID: prefer the value pre-computed by the repository, which is
    // the exact same integer sent to the Cloud Function for token generation.
    // This guarantees token-UID == joinChannel-UID → avoids errInvalidToken.
    final int localUid;
    final extraUid = session.extra['uid'];
    if (extraUid is int && extraUid > 0) {
      localUid = extraUid;
      // Sync the mapper so reverse-lookup (remote users → userId) still works
      _uidMapper.register(session.localUserId, localUid);
    } else {
      localUid = _uidMapper.toAgoraUid(session.localUserId);
    }
    debugPrint('[AgoraRtcService] joinSession: channelId=${session.roomId}, uid=$localUid');

    // If extra contains opponent UID, map it in advance
    if (session.extra.containsKey('opponentUserId') && session.extra.containsKey('opponentUid')) {
      final oppId = session.extra['opponentUserId'] as String;
      final oppUid = (session.extra['opponentUid'] as num).toInt();
      _uidMapper.register(oppId, oppUid);
    }

    // Add local participant
    _participants[session.localUserId] = RtcParticipantMediaState(
      participantId: session.localUserId,
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
    if (_engine != null) {
      // Timeout guards: if joinChannel failed (e.g. errInvalidToken) the engine
      // may never have actually joined, and leaveChannel can hang indefinitely.
      await _engine!.stopPreview().timeout(
        const Duration(seconds: 3),
        onTimeout: () => debugPrint('[AgoraRtcService] stopPreview timed out — skipping'),
      );
      await _engine!.leaveChannel().timeout(
        const Duration(seconds: 5),
        onTimeout: () => debugPrint('[AgoraRtcService] leaveChannel timed out — skipping'),
      );
      await _engine!.disableAudio().timeout(
        const Duration(seconds: 3),
        onTimeout: () => debugPrint('[AgoraRtcService] disableAudio timed out — skipping'),
      );
    }
    _activeSession = null;
    _participants.clear();
    _emitParticipants();
    _updateConnectionState(RtcConnectionState.disconnected);
  }

  @override
  Future<void> setMicrophoneMuted(bool muted) async {
    _isMicrophoneMuted = muted;
    if (_engine != null) {
      await _engine!.muteLocalAudioStream(muted);
    }
    final localId = _activeSession?.localUserId;
    if (localId != null && _participants.containsKey(localId)) {
      _participants[localId] = _participants[localId]!.copyWith(isAudioMuted: muted);
      _emitParticipants();
    }
  }

  @override
  Future<void> setCameraEnabled(bool enabled) async {
    _isCameraEnabled = enabled;
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
    final localId = _activeSession?.localUserId;
    if (localId != null && _participants.containsKey(localId)) {
      _participants[localId] = _participants[localId]!.copyWith(isVideoEnabled: enabled);
      _emitParticipants();
    }
  }

  @override
  Future<void> setSpeakerEnabled(bool enabled) async {
    _isSpeakerEnabled = enabled;
    if (_engine != null) {
      await _engine!.setEnableSpeakerphone(enabled);
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
