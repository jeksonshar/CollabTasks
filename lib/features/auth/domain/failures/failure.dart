abstract class Failure {
  const Failure(this.message);

  final String message;
}

class WrongPasswordFailure extends Failure {
  const WrongPasswordFailure([super.message = 'Wrong password.']);
}

class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure([super.message = 'User not found.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error.']);
}

class ActionCodeExpiredFailure extends Failure {
  const ActionCodeExpiredFailure([super.message = 'Action code expired.']);
}

class EmailAlreadyInUseFailure extends Failure {
  const EmailAlreadyInUseFailure([super.message = 'Email is already in use.']);
}

class InvalidEmailFailure extends Failure {
  const InvalidEmailFailure([super.message = 'Invalid email address.']);
}

class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure([super.message = 'Password is too weak.']);
}

class TooManyRequestsFailure extends Failure {
  const TooManyRequestsFailure([super.message = 'Too many requests.']);
}

class UserDisabledFailure extends Failure {
  const UserDisabledFailure([super.message = 'User account is disabled.']);
}

class EmailNotVerifiedFailure extends Failure {
  const EmailNotVerifiedFailure([super.message = 'Email is not verified.']);
}

class EmailNotVerifiedConfirmEmailFailure extends EmailNotVerifiedFailure {
  const EmailNotVerifiedConfirmEmailFailure([super.message = 'Confirm email before continuing.']);
}

class EmailNotVerifiedSentFailure extends EmailNotVerifiedFailure {
  const EmailNotVerifiedSentFailure([
    super.message = 'Verification email sent. Confirm your email, then sign in.',
  ]);
}

class InvalidCredentialFailure extends Failure {
  const InvalidCredentialFailure([super.message = 'Invalid credential.']);
}

class OperationNotAllowedFailure extends Failure {
  const OperationNotAllowedFailure([super.message = 'Operation is not allowed.']);
}

class ResetPasswordUnavailableFailure extends OperationNotAllowedFailure {
  const ResetPasswordUnavailableFailure([
    super.message = 'Reset password flow is not available for this account.',
  ]);
}

class GoogleSignInNotSupportedFailure extends OperationNotAllowedFailure {
  const GoogleSignInNotSupportedFailure([
    super.message = 'Google Sign-In is not supported by the current configuration.',
  ]);
}

class NoPasswordProviderFailure extends Failure {
  const NoPasswordProviderFailure([
    super.message = 'This account does not support password reset.',
  ]);
}

class PasswordResetRequiredFailure extends NoPasswordProviderFailure {
  const PasswordResetRequiredFailure([
    super.message = 'Password reset is required before sign-in.',
  ]);
}

class CanceledByUserFailure extends Failure {
  const CanceledByUserFailure([super.message = 'Operation was canceled by user.']);
}

class UnknownAuthFailure extends Failure {
  const UnknownAuthFailure([super.message = 'Unknown authentication error.']);
}

class ConfirmationNotCompleteFailure extends UnknownAuthFailure {
  const ConfirmationNotCompleteFailure([super.message = 'Confirmation is not complete.']);
}
