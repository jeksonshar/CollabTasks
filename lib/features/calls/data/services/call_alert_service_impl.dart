import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:collab_tasks/features/calls/domain/services/call_alert_service.dart';
import 'package:vibration/vibration.dart';

class CallAlertServiceImpl implements CallAlertService {
  static const String _outgoingRingtoneAsset = 'audio/outgoing_ringtone.mp3';
  static const String _incomingRingtoneAsset = 'audio/incoming_ringtone.mp3';
  static const List<int> _incomingVibrationPattern = [1000, 1000];

  final AudioPlayer _audioPlayer;
  bool _audioContextConfigured = false;

  CallAlertServiceImpl({AudioPlayer? audioPlayer}) : _audioPlayer = audioPlayer ?? AudioPlayer();

  @override
  Future<void> startOutgoingRingtone() async {
    await stop();
    try {
      await _configureAudioContext();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource(_outgoingRingtoneAsset));
    } catch (error, stackTrace) {
      await _stopBestEffort();
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<void> startIncomingRingtone() async {
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
    } catch (_) {
      // Continue releasing the player even if an OS stop operation fails.
    }

    try {
      await _audioPlayer.dispose();
    } catch (_) {
      // dispose() has no error channel; avoid an unhandled async error.
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
    } catch (_) {
      // Preserve the original playback error.
    }

    try {
      await Vibration.cancel();
    } catch (_) {
      // Preserve the original playback error.
    }
  }
}
