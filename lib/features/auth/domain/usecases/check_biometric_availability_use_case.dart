import 'package:collab_tasks/features/auth/data/services/biometric_service.dart';

/// Checks whether the current device supports and has enrolled biometric credentials.
class CheckBiometricAvailabilityUseCase {
  const CheckBiometricAvailabilityUseCase(this._service);

  final BiometricService _service;

  Future<bool> call() => _service.canAuthenticate();
}
