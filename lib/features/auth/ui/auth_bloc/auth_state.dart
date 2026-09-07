import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:collab_tasks/features/auth/domain/failures/failure.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_error_type.dart';
import 'package:equatable/equatable.dart';

enum AuthStatus {
  initial,
  loadingBeforeStart,
  loadingFormSubmit,
  authenticated,
  unauthenticated,
  failure,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.failure,
    this.errorType,
    this.passwordResetEmailSent = false,
    this.signUpCodeResent = false,
    this.signUpConfirmed = false,
    this.requiresSignUpConfirmation = false,
    this.pendingConfirmationEmail,
    this.requiresResetPasswordConfirmation = false,
    this.pendingResetPasswordEmail,
    this.passwordResetConfirmed = false,
    this.offerBiometricSetup = false,
  });

  final AuthStatus status;
  final AuthUser? user;
  final Failure? failure;
  final AuthErrorType? errorType;
  final bool passwordResetEmailSent;
  final bool signUpCodeResent;
  final bool signUpConfirmed;
  final bool requiresSignUpConfirmation;
  final String? pendingConfirmationEmail;
  final bool requiresResetPasswordConfirmation;
  final String? pendingResetPasswordEmail;
  final bool passwordResetConfirmed;

  /// `true` for exactly one emission after a successful login on a device that
  /// supports biometrics but has not yet configured biometric login.
  /// Consumed by a BlocListener in [AppAuthGate] which shows [BiometricOfferDialog].
  final bool offerBiometricSetup;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    Failure? failure,
    AuthErrorType? errorType,
    bool clearFailure = false,
    bool? passwordResetEmailSent,
    bool? signUpCodeResent,
    bool? signUpConfirmed,
    bool? requiresSignUpConfirmation,
    String? pendingConfirmationEmail,
    bool clearPendingConfirmationEmail = false,
    bool? requiresResetPasswordConfirmation,
    String? pendingResetPasswordEmail,
    bool clearPendingResetPasswordEmail = false,
    bool? passwordResetConfirmed,
    bool? offerBiometricSetup,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      failure: clearFailure ? null : failure ?? this.failure,
      errorType: clearFailure ? null : errorType ?? this.errorType,
      passwordResetEmailSent: passwordResetEmailSent ?? this.passwordResetEmailSent,
      signUpCodeResent: signUpCodeResent ?? this.signUpCodeResent,
      signUpConfirmed: signUpConfirmed ?? this.signUpConfirmed,
      requiresSignUpConfirmation: requiresSignUpConfirmation ?? this.requiresSignUpConfirmation,
      pendingConfirmationEmail: clearPendingConfirmationEmail
          ? null
          : pendingConfirmationEmail ?? this.pendingConfirmationEmail,
      requiresResetPasswordConfirmation:
          requiresResetPasswordConfirmation ?? this.requiresResetPasswordConfirmation,
      pendingResetPasswordEmail: clearPendingResetPasswordEmail
          ? null
          : pendingResetPasswordEmail ?? this.pendingResetPasswordEmail,
      passwordResetConfirmed: passwordResetConfirmed ?? this.passwordResetConfirmed,
      offerBiometricSetup: offerBiometricSetup ?? this.offerBiometricSetup,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    failure,
    errorType,
    passwordResetEmailSent,
    signUpCodeResent,
    signUpConfirmed,
    requiresSignUpConfirmation,
    pendingConfirmationEmail,
    requiresResetPasswordConfirmation,
    pendingResetPasswordEmail,
    passwordResetConfirmed,
    offerBiometricSetup,
  ];
}
