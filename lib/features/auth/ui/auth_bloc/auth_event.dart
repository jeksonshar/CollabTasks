import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthSubscriptionStarted extends AuthEvent {
  const AuthSubscriptionStarted();
}

class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

class AuthResetPasswordRequested extends AuthEvent {
  const AuthResetPasswordRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

class AuthConfirmResetPasswordRequested extends AuthEvent {
  const AuthConfirmResetPasswordRequested({
    required this.email,
    required this.code,
    required this.newPassword,
  });

  final String email;
  final String code;
  final String newPassword;

  @override
  List<Object?> get props => [email, code, newPassword];
}

class AuthConfirmSignUpRequested extends AuthEvent {
  const AuthConfirmSignUpRequested({required this.email, required this.code});

  final String email;
  final String code;

  @override
  List<Object?> get props => [email, code];
}

class AuthResendSignUpCodeRequested extends AuthEvent {
  const AuthResendSignUpCodeRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

class AuthLogOutRequested extends AuthEvent {
  const AuthLogOutRequested();
}

class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}
