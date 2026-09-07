import 'package:equatable/equatable.dart';

abstract class LockEvent extends Equatable {
  const LockEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched at cold start to check credentials and lock if enabled.
class LockCheckRequested extends LockEvent {
  const LockCheckRequested();
}

/// Dispatched when the app enters background (paused, hidden, or inactive).
class LockAppPaused extends LockEvent {
  const LockAppPaused();
}

/// Dispatched when the app returns to foreground (resumed).
class LockAppResumed extends LockEvent {
  const LockAppResumed();
}

/// Dispatched when the user taps or interacts with the screen.
/// Resets the 5-minute foreground inactivity timer.
class LockUserInteractionOccurred extends LockEvent {
  const LockUserInteractionOccurred();
}

/// Dispatched when the authentication status changes (login / logout).
class LockAuthStatusChanged extends LockEvent {
  const LockAuthStatusChanged({required this.isAuthenticated});

  final bool isAuthenticated;

  @override
  List<Object?> get props => [isAuthenticated];
}

/// Dispatched when the user taps "Unlock" on [LockScreenWidget].
class LockAuthenticateRequested extends LockEvent {
  const LockAuthenticateRequested();
}

/// Dispatched when the user taps "Sign in with password" on [LockScreenWidget].
/// The UI listener will call [AuthLogOutRequested] and navigate to auth screen.
class LockSignInWithPasswordRequested extends LockEvent {
  const LockSignInWithPasswordRequested();
}

/// Dispatched from [SettingsScreen] toggle or [BiometricOfferDialog].
///
/// When [enabled] is `true`, biometric confirmation is required before saving.
class LockBiometricToggled extends LockEvent {
  const LockBiometricToggled({required this.enabled});

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

/// Dispatched after the post-login biometric offer dialog is dismissed.
/// [accepted] is `true` if user tapped "Enable".
class LockBiometricOfferResponded extends LockEvent {
  const LockBiometricOfferResponded({required this.accepted});

  final bool accepted;

  @override
  List<Object?> get props => [accepted];
}
