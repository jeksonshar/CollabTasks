import 'package:collab_tasks/features/auth/data/services/biometric_service.dart';

/// Triggers the OS biometric authentication dialog.
///
/// Returns `true` on success, `false` on user cancellation or failure.
class AuthenticateWithBiometricUseCase {
  const AuthenticateWithBiometricUseCase(this._service);

  final BiometricService _service;

  Future<bool> call({required String localizedReason}) =>
      _service.authenticate(localizedReason: localizedReason);
}
