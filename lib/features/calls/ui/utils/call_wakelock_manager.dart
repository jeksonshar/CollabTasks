import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the display awake while one or more call surfaces are visible.
///
/// The reference count prevents an incoming dialog's disposal from disabling
/// the wake lock while an accepted video-call screen is taking ownership.
class CallWakelockManager {
  CallWakelockManager._();

  static int _owners = 0;
  static bool _isEnabled = false;
  static Future<void> _pendingUpdate = Future<void>.value();

  static Future<void> acquire() {
    _owners++;
    return _synchronize();
  }

  static Future<void> release() {
    if (_owners > 0) _owners--;
    return _synchronize();
  }

  static Future<void> _synchronize() {
    final update = _pendingUpdate.then((_) async {
      final shouldEnable = _owners > 0;
      if (_isEnabled == shouldEnable) return;

      try {
        if (shouldEnable) {
          await WakelockPlus.enable();
        } else {
          await WakelockPlus.disable();
        }
        _isEnabled = shouldEnable;
      } catch (error, stackTrace) {
        debugPrint('[CallWakelockManager] Failed to update wakelock: $error\n$stackTrace');
      }
    });

    _pendingUpdate = update;
    return update;
  }
}
