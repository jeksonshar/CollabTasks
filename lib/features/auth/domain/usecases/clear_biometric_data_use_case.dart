import 'package:collab_tasks/features/auth/data/services/biometric_secure_storage.dart';

/// Clears all biometric-related data from secure storage.
///
/// Called on explicit user logout to ensure a clean state on next login.
class ClearBiometricDataUseCase {
  const ClearBiometricDataUseCase(this._storage);

  final BiometricSecureStorage _storage;

  Future<void> call() => _storage.clearAll();
}
