import 'package:collab_tasks/features/auth/data/services/biometric_secure_storage.dart';

/// Persists the biometric-enabled flag to secure storage.
class SetBiometricEnabledUseCase {
  const SetBiometricEnabledUseCase(this._storage);

  final BiometricSecureStorage _storage;

  Future<void> call({required bool value}) => _storage.setBiometricEnabled(value: value);
}
