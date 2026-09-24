import 'dart:async';
import 'dart:developer' as developer;

import 'package:audioplayers/audioplayers.dart';
import 'package:collab_tasks/features/calls/domain/services/call_alert_service.dart';
import 'package:vibration/vibration.dart';

class CallAlertServiceImpl implements CallAlertService {
  static const String _outgoingRingtoneAsset = 'audio/outgoing_ringtone.mp3';
  static const String _incomingRingtoneAsset = 'audio/incoming_ringtone.mp3';
  static const List<int> _incomingVibrationPattern = [1000, 1000];

  final AudioPlayer _audioPlayer;
  bool _audioContextConfigured = false;

  /// Prevents concurrent start calls from racing: the second caller waits for
  /// the first stop()+play() sequence to finish before proceeding.
  bool _isStarting = false;

  CallAlertServiceImpl({AudioPlayer? audioPlayer}) : _audioPlayer = audioPlayer ?? AudioPlayer();

  @override
  Future<void> startOutgoingRingtone() async {
    // Spin-wait until any in-progress start operation completes.
    while (_isStarting) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
    _isStarting = true;
    await stop();
    try {
      await _configureAudioContext();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource(_outgoingRingtoneAsset));
    } catch (error, stackTrace) {
      await _stopBestEffort();
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      _isStarting = false;
    }
  }

  @override
  Future<void> startIncomingRingtone() async {
    while (_isStarting) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
    _isStarting = true;
    await stop();
    try {
      await _configureAudioContext();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource(_incomingRingtoneAsset));

      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(pattern: _incomingVibrationPattern, repeat: 0);
      }
    } catch (error, stackTrace) {
      await _stopBestEffort();
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      _isStarting = false;
    }
  }

  @override
  Future<void> stop() async {
    Object? firstError;
    StackTrace? firstStackTrace;

    try {
      await _audioPlayer.stop();
    } catch (error, stackTrace) {
      firstError = error;
      firstStackTrace = stackTrace;
    }

    try {
      await Vibration.cancel();
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }

    // Reset flag so the audio context is re-applied on the next start call.
    // Without this, the audio session stays in inCommunication mode between calls.
    _audioContextConfigured = false;

    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStackTrace!);
    }
  }

  @override
  void dispose() {
    unawaited(_dispose());
  }

  Future<void> _dispose() async {
    try {
      await stop();
    } catch (error, stackTrace) {
      // Continue releasing the player even if an OS stop operation fails.
      developer.log(
        'Failed to stop call alert during disposal.',
        name: 'CallAlertServiceImpl',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      await _audioPlayer.dispose();
    } catch (error, stackTrace) {
      // dispose() has no error channel; avoid an unhandled async error.
      developer.log(
        'Failed to dispose audio player.',
        name: 'CallAlertServiceImpl',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _configureAudioContext() async {
    if (_audioContextConfigured) return;

    await _audioPlayer.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          audioMode: AndroidAudioMode.inCommunication,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.notificationRingtone,
          audioFocus: AndroidAudioFocus.gainTransient,
          stayAwake: true,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playAndRecord,
          options: const {AVAudioSessionOptions.defaultToSpeaker},
        ),
      ),
    );
    _audioContextConfigured = true;
  }

  Future<void> _stopBestEffort() async {
    try {
      await _audioPlayer.stop();
    } catch (error, stackTrace) {
      // Preserve the original playback error.
      developer.log(
        'Best-effort audio stop failed after an alert error.',
        name: 'CallAlertServiceImpl',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      await Vibration.cancel();
    } catch (error, stackTrace) {
      // Preserve the original playback error.
      developer.log(
        'Best-effort vibration cancellation failed after an alert error.',
        name: 'CallAlertServiceImpl',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
