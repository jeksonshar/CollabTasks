import 'dart:async';

import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_connection_state.dart';
import 'package:collab_tasks/features/calls/domain/models/rtc_participant_media_state.dart';
import 'package:collab_tasks/features/calls/domain/services/rtc_service.dart';

class FakeRtcService implements RtcService {
  final _connectionStateController = StreamController<RtcConnectionState>.broadcast();
  final _participantMediaStatesController =
      StreamController<List<RtcParticipantMediaState>>.broadcast();

  RtcConnectionState _currentState = RtcConnectionState.disconnected;
  final Map<String, RtcParticipantMediaState> _participants = {};

  CallSession? _activeSession;
  bool _isMicrophoneMuted = false;
  bool _isCameraEnabled = true;
  int _switchCameraCallCount = 0;
  int _joinCallCount = 0;
  int _leaveCallCount = 0;
  CallSession? _lastJoinedSession;
  bool _isDisposed = false;

  // --- Test & Inspection helpers ---
  CallSession? get activeSession => _activeSession;

  CallSession? get lastJoinedSession => _lastJoinedSession;

  bool get isJoined => _activeSession != null;

  int get joinCallCount => _joinCallCount;

  int get leaveCallCount => _leaveCallCount;

  bool get isMicrophoneMuted => _isMicrophoneMuted;

  bool get isCameraEnabled => _isCameraEnabled;

  int get switchCameraCallCount => _switchCameraCallCount;

  bool get isDisposed => _isDisposed;

  /// Simulates an arbitrary connection state change (e.g. connected, reconnecting, failed).
  void simulateConnectionState(RtcConnectionState state) {
    _currentState = state;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }

  /// Simulates a remote participant joining the session.
  void simulateParticipantJoined(RtcParticipantMediaState participant) {
    _participants[participant.participantId] = participant;
    _emitParticipants();
  }

  /// Simulates a remote participant leaving the session.
  void simulateParticipantLeft(String participantId) {
    _participants.remove(participantId);
    _emitParticipants();
  }

  /// Simulates speaking state of any participant.
  void simulateSpeaking(String participantId, bool isSpeaking, {double audioLevel = 0.5}) {
    final existing = _participants[participantId];
    if (existing != null) {
      _participants[participantId] = existing.copyWith(
        isSpeaking: isSpeaking,
        audioLevel: isSpeaking ? audioLevel : 0.0,
      );
      _emitParticipants();
    }
  }

  /// Simulates media state updates (e.g. remote muted/unmuted, camera toggled).
  void simulateParticipantMediaChanged(RtcParticipantMediaState updatedState) {
    _participants[updatedState.participantId] = updatedState;
    _emitParticipants();
  }

  void _emitParticipants() {
    if (!_participantMediaStatesController.isClosed) {
      _participantMediaStatesController.add(_participants.values.toList());
    }
  }

  // --- RtcService implementation ---

  @override
  RtcConnectionState get currentConnectionState => _currentState;

  @override
  Stream<RtcConnectionState> get connectionStateStream => _connectionStateController.stream;

  @override
  List<RtcParticipantMediaState> get currentParticipantMediaStates => _participants.values.toList();

  @override
  Stream<List<RtcParticipantMediaState>> get participantMediaStatesStream =>
      _participantMediaStatesController.stream;

  @override
  Future<void> joinSession(CallSession session) async {
    if (_isDisposed) {
      throw StateError('Cannot join session on a disposed RtcService');
    }
    _joinCallCount++;
    _lastJoinedSession = session;
    _activeSession = session;

    // Transition: connecting -> connected
    simulateConnectionState(RtcConnectionState.connecting);

    // Add local participant
    _participants[session.localUserId] = RtcParticipantMediaState(
      participantId: session.localUserId,
      isLocal: true,
      isAudioMuted: _isMicrophoneMuted,
      isVideoEnabled: _isCameraEnabled,
    );
    _emitParticipants();

    simulateConnectionState(RtcConnectionState.connected);
  }

  @override
  Future<void> leaveSession() async {
    _leaveCallCount++;
    _activeSession = null;
    _participants.clear();
    _emitParticipants();
    simulateConnectionState(RtcConnectionState.disconnected);
  }

  @override
  Future<void> setMicrophoneMuted(bool muted) async {
    _isMicrophoneMuted = muted;
    final localId = _activeSession?.localUserId;
    if (localId != null && _participants.containsKey(localId)) {
      _participants[localId] = _participants[localId]!.copyWith(isAudioMuted: muted);
      _emitParticipants();
    }
  }

  @override
  Future<void> setCameraEnabled(bool enabled) async {
    _isCameraEnabled = enabled;
    final localId = _activeSession?.localUserId;
    if (localId != null && _participants.containsKey(localId)) {
      _participants[localId] = _participants[localId]!.copyWith(isVideoEnabled: enabled);
      _emitParticipants();
    }
  }

  @override
  Future<void> switchCamera() async {
    _switchCameraCallCount++;
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await leaveSession();
    await _connectionStateController.close();
    await _participantMediaStatesController.close();
  }
}
