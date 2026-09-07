import 'package:equatable/equatable.dart';

enum LockStatus {
  /// No lock — app content is fully accessible.
  idle,

  /// App is locked; biometric or password required.
  locked,

  /// Biometric dialog is in progress.
  authenticating,

  /// Privacy screen shown while app is in the OS task switcher.
  privacyScreen,

  /// Offering the user to enable biometrics after a successful login.
  offeringBiometrics,

  /// "Sign in with password" was requested — UI should trigger logout.
  requiresLogout,
}

class LockState extends Equatable {
  const LockState({
    this.status = LockStatus.idle,
    this.isBiometricEnabled = false,
    this.isBiometricAvailable = false,
    this.authenticationFailed = false,
  });

  /// Current lock lifecycle status.
  final LockStatus status;

  /// Whether the user has enabled biometric login.
  final bool isBiometricEnabled;

  /// Whether the device supports and has enrolled biometrics.
  final bool isBiometricAvailable;

  /// Set to `true` after a failed biometric attempt so the UI can show
  /// "Retry" and "Sign in with password" buttons.
  final bool authenticationFailed;

  LockState copyWith({
    LockStatus? status,
    bool? isBiometricEnabled,
    bool? isBiometricAvailable,
    bool? authenticationFailed,
  }) {
    return LockState(
      status: status ?? this.status,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      authenticationFailed: authenticationFailed ?? this.authenticationFailed,
    );
  }

  @override
  List<Object?> get props => [
    status,
    isBiometricEnabled,
    isBiometricAvailable,
    authenticationFailed,
  ];
}
