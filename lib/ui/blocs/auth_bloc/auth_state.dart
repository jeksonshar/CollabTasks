import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:collab_tasks/features/auth/domain/failures/failure.dart';
import 'package:equatable/equatable.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.failure,
    this.passwordResetEmailSent = false,
  });

  final AuthStatus status;
  final AuthUser? user;
  final Failure? failure;
  final bool passwordResetEmailSent;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    Failure? failure,
    bool clearFailure = false,
    bool? passwordResetEmailSent,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      failure: clearFailure ? null : failure ?? this.failure,
      passwordResetEmailSent: passwordResetEmailSent ?? this.passwordResetEmailSent,
    );
  }

  @override
  List<Object?> get props => [status, user, failure, passwordResetEmailSent];
}
