import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thrown when the OS has invalidated secure storage keys
/// (e.g. a new fingerprint was enrolled or biometrics were changed).
/// The caller should disable biometric login and force re-authentication.
class BiometricKeysInvalidatedException implements Exception {
  const BiometricKeysInvalidatedException();

  @override
  String toString() => 'BiometricKeysInvalidatedException: secure storage keys were invalidated';
}

/// Encrypted storage for biometric preference flag using [FlutterSecureStorage].
///
/// Key invalidation (new fingerprint enrolled, biometrics cleared) is detected
/// via [PlatformException] and surfaces as [BiometricKeysInvalidatedException].
class BiometricSecureStorage {
  BiometricSecureStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            // v11: AES-GCM with RSA OAEP key wrapping (default — no extra params needed)
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
          );

  final FlutterSecureStorage _storage;

  static const _keyBiometricEnabled = 'isBiometricsEnabled';

  /// Returns the stored biometric enabled flag, or `null` if never set.
  ///
  /// Throws [BiometricKeysInvalidatedException] on OS key invalidation.
  Future<bool?> getBiometricEnabled() async {
    try {
      final raw = await _storage.read(key: _keyBiometricEnabled);
      if (raw == null) return null;
      return raw == 'true';
    } on PlatformException catch (e, st) {
      debugPrint('BiometricSecureStorage.getBiometricEnabled error: $e\n$st');
      // Key invalidation codes vary by platform; safest is to reset.
      await _resetOnInvalidation();
      throw const BiometricKeysInvalidatedException();
    }
  }

  /// Persists the biometric enabled flag.
  ///
  /// Throws [BiometricKeysInvalidatedException] on OS key invalidation.
  Future<void> setBiometricEnabled({required bool value}) async {
    try {
      await _storage.write(key: _keyBiometricEnabled, value: value.toString());
    } on PlatformException catch (e, st) {
      debugPrint('BiometricSecureStorage.setBiometricEnabled error: $e\n$st');
      await _resetOnInvalidation();
      throw const BiometricKeysInvalidatedException();
    }
  }

  /// Deletes all keys managed by this storage (called on logout).
  Future<void> clearAll() async {
    try {
      await _storage.delete(key: _keyBiometricEnabled);
    } on PlatformException catch (e, st) {
      debugPrint('BiometricSecureStorage.clearAll error: $e\n$st');
    }
  }

  /// Silently resets the stored flag to `false` after key invalidation.
  Future<void> _resetOnInvalidation() async {
    try {
      await _storage.delete(key: _keyBiometricEnabled);
    } catch (_) {
      // Best-effort cleanup; ignore further errors.
    }
  }
}
