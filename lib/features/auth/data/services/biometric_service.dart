import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Exception thrown when biometric authentication is not available on the device.
class BiometricNotAvailableException implements Exception {
  const BiometricNotAvailableException(this.message);

  final String message;

  @override
  String toString() => 'BiometricNotAvailableException: $message';
}

/// Wraps [LocalAuthentication] providing safe biometric capability checks
/// and authentication flow with structured error handling.
class BiometricService {
  BiometricService({LocalAuthentication? auth}) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// Returns `true` if the device has biometric hardware AND enrolled credentials.
  Future<bool> canAuthenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException catch (e, st) {
      debugPrint('BiometricService.canAuthenticate error: $e\n$st');
      return false;
    }
  }

  /// Triggers the OS biometric prompt.
  ///
  /// Returns `true` on success, `false` on cancellation or failure.
  /// [localizedReason] is shown in the system dialog.
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      debugPrint(
        'BiometricService.authenticate: starting authentication with reason "$localizedReason"...',
      );
      final result = await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: false, // allow device PIN as fallback
          stickyAuth: true,
        ),
      );
      debugPrint('BiometricService.authenticate: completed with result: $result');
      return result;
    } on PlatformException catch (e, st) {
      debugPrint('BiometricService.authenticate error: ${e.code} ${e.message}\n$st');
      // User cancelled or not enrolled — treat as failure, not crash
      return false;
    }
  }

  /// Returns the list of enrolled biometric types (e.g. face, fingerprint).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e, st) {
      debugPrint('BiometricService.getAvailableBiometrics error: $e\n$st');
      return const [];
    }
  }
}
