import 'package:collab_tasks/features/auth/domain/failures/failure.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';

enum AuthErrorType {
  wrongPassword,
  userNotFound,
  network,
  actionCodeExpired,
  emailAlreadyInUse,
  invalidEmail,
  weakPassword,
  tooManyRequests,
  userDisabled,
  emailNotVerified,
  emailNotVerifiedConfirmEmail,
  emailNotVerifiedSent,
  invalidCredential,
  operationNotAllowed,
  resetNotAvailable,
  googleSignInNotSupported,
  passwordResetRequired,
  noPasswordProvider,
  canceledByUser,
  confirmationNotComplete,
  unknown,
}

extension AuthErrorTypeX on AuthErrorType {
  String label(AppLocalizations localization) {
    switch (this) {
      case AuthErrorType.wrongPassword:
        return localization.authErrorWrongPassword;
      case AuthErrorType.userNotFound:
        return localization.authErrorUserNotFound;
      case AuthErrorType.network:
        return localization.authErrorNetwork;
      case AuthErrorType.actionCodeExpired:
        return localization.authErrorActionCodeExpired;
      case AuthErrorType.emailAlreadyInUse:
        return localization.authErrorEmailAlreadyInUse;
      case AuthErrorType.invalidEmail:
        return localization.authErrorInvalidEmail;
      case AuthErrorType.weakPassword:
        return localization.authErrorWeakPassword;
      case AuthErrorType.tooManyRequests:
        return localization.authErrorTooManyRequests;
      case AuthErrorType.userDisabled:
        return localization.authErrorUserDisabled;
      case AuthErrorType.emailNotVerified:
        return localization.authErrorEmailNotVerified;
      case AuthErrorType.emailNotVerifiedConfirmEmail:
        return localization.authErrorEmailNotVerifiedConfirmEmail;
      case AuthErrorType.emailNotVerifiedSent:
        return localization.authErrorEmailNotVerifiedSent;
      case AuthErrorType.invalidCredential:
        return localization.authErrorInvalidCredential;
      case AuthErrorType.operationNotAllowed:
        return localization.authErrorOperationNotAllowed;
      case AuthErrorType.resetNotAvailable:
        return localization.authErrorResetNotAvailable;
      case AuthErrorType.googleSignInNotSupported:
        return localization.authErrorGoogleSignInNotSupported;
      case AuthErrorType.passwordResetRequired:
        return localization.authErrorPasswordResetRequired;
      case AuthErrorType.noPasswordProvider:
        return localization.authErrorNoPasswordProvider;
      case AuthErrorType.canceledByUser:
        return localization.authErrorCanceledByUser;
      case AuthErrorType.confirmationNotComplete:
        return localization.authErrorConfirmationNotComplete;
      case AuthErrorType.unknown:
        return localization.authErrorUnknown;
    }
  }
}

class AuthErrorMapper {
  static AuthErrorType fromFailure(Failure failure) {
    if (failure is WrongPasswordFailure) {
      return AuthErrorType.wrongPassword;
    }
    if (failure is UserNotFoundFailure) {
      return AuthErrorType.userNotFound;
    }
    if (failure is NetworkFailure) {
      return AuthErrorType.network;
    }
    if (failure is ActionCodeExpiredFailure) {
      return AuthErrorType.actionCodeExpired;
    }
    if (failure is EmailAlreadyInUseFailure) {
      return AuthErrorType.emailAlreadyInUse;
    }
    if (failure is InvalidEmailFailure) {
      return AuthErrorType.invalidEmail;
    }
    if (failure is WeakPasswordFailure) {
      return AuthErrorType.weakPassword;
    }
    if (failure is TooManyRequestsFailure) {
      return AuthErrorType.tooManyRequests;
    }
    if (failure is UserDisabledFailure) {
      return AuthErrorType.userDisabled;
    }
    if (failure is EmailNotVerifiedConfirmEmailFailure) {
      return AuthErrorType.emailNotVerifiedConfirmEmail;
    }
    if (failure is EmailNotVerifiedSentFailure) {
      return AuthErrorType.emailNotVerifiedSent;
    }
    if (failure is EmailNotVerifiedFailure) {
      return AuthErrorType.emailNotVerified;
    }
    if (failure is InvalidCredentialFailure) {
      return AuthErrorType.invalidCredential;
    }
    if (failure is ResetPasswordUnavailableFailure) {
      return AuthErrorType.resetNotAvailable;
    }
    if (failure is GoogleSignInNotSupportedFailure) {
      return AuthErrorType.googleSignInNotSupported;
    }
    if (failure is OperationNotAllowedFailure) {
      return AuthErrorType.operationNotAllowed;
    }
    if (failure is PasswordResetRequiredFailure) {
      return AuthErrorType.passwordResetRequired;
    }
    if (failure is NoPasswordProviderFailure) {
      return AuthErrorType.noPasswordProvider;
    }
    if (failure is CanceledByUserFailure) {
      return AuthErrorType.canceledByUser;
    }
    if (failure is ConfirmationNotCompleteFailure) {
      return AuthErrorType.confirmationNotComplete;
    }
    if (failure is UnknownAuthFailure) {
      return AuthErrorType.unknown;
    }
    return AuthErrorType.unknown;
  }
}
