import 'package:collab_tasks/features/auth/data/services/biometric_secure_storage.dart';

/// Reads the persisted biometric-enabled flag from secure storage.
///
/// Returns `null` if the flag was never set (first run / after logout).
class GetBiometricEnabledUseCase {
  const GetBiometricEnabledUseCase(this._storage);

  final BiometricSecureStorage _storage;

  Future<bool?> call() => _storage.getBiometricEnabled();
}
