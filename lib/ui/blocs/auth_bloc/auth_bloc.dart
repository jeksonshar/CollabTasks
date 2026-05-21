import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:collab_tasks/features/auth/domain/failures/failure.dart';
import 'package:collab_tasks/features/auth/domain/result/result.dart';
import 'package:collab_tasks/features/auth/domain/usecases/log_out_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/login_with_email_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/register_with_email_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/reset_password_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/watch_auth_state_use_case.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required RegisterWithEmailUseCase registerWithEmailUseCase,
    required LoginWithEmailUseCase loginWithEmailUseCase,
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
    required LogOutUseCase logOutUseCase,
    required WatchAuthStateUseCase watchAuthStateUseCase,
  }) : _registerWithEmailUseCase = registerWithEmailUseCase,
       _loginWithEmailUseCase = loginWithEmailUseCase,
       _signInWithGoogleUseCase = signInWithGoogleUseCase,
       _resetPasswordUseCase = resetPasswordUseCase,
       _logOutUseCase = logOutUseCase,
       _watchAuthStateUseCase = watchAuthStateUseCase,
       super(const AuthState()) {
    on<AuthSubscriptionStarted>(_onSubscriptionStarted);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthLogOutRequested>(_onLogOutRequested);
    on<AuthErrorCleared>(_onErrorCleared);
  }

  final RegisterWithEmailUseCase _registerWithEmailUseCase;
  final LoginWithEmailUseCase _loginWithEmailUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final LogOutUseCase _logOutUseCase;
  final WatchAuthStateUseCase _watchAuthStateUseCase;

  Future<void> _onSubscriptionStarted(
    AuthSubscriptionStarted event,
    Emitter<AuthState> emit,
  ) async {
    await emit.forEach(
      _watchAuthStateUseCase(),
      onData: (user) {
        if (user == null) {
          return state.copyWith(
            status: AuthStatus.unauthenticated,
            user: null,
            clearFailure: true,
            passwordResetEmailSent: false,
          );
        }

        return state.copyWith(status: AuthStatus.authenticated, user: user, clearFailure: true);
      },
      onError: (_, _) => state.copyWith(status: AuthStatus.failure),
    );
  }

  Future<void> _onRegisterRequested(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, clearFailure: true));

    final result = await _registerWithEmailUseCase(email: event.email, password: event.password);

    _handleAuthResult(result, emit);
  }

  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, clearFailure: true));

    final result = await _loginWithEmailUseCase(email: event.email, password: event.password);

    _handleAuthResult(result, emit);
  }

  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearFailure: true));
    final result = await _signInWithGoogleUseCase();
    _handleAuthResult(result, emit);
  }

  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(status: AuthStatus.loading, clearFailure: true, passwordResetEmailSent: false),
    );

    final result = await _resetPasswordUseCase(email: event.email);
    switch (result) {
      case Success<void, Failure>():
        debugPrint('AuthBloc.resetPassword: success for email=${event.email}');
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearFailure: true,
            passwordResetEmailSent: true,
          ),
        );
      case FailureResult<void, Failure>(:final failure):
        debugPrint(
          'AuthBloc.resetPassword: failure type=${failure.runtimeType}, message=${failure.message}',
        );
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            failure: failure,
            passwordResetEmailSent: false,
          ),
        );
    }
  }

  Future<void> _onLogOutRequested(AuthLogOutRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, clearFailure: true));
    final result = await _logOutUseCase();

    switch (result) {
      case Success<void, Failure>():
        emit(state.copyWith(status: AuthStatus.unauthenticated, user: null, clearFailure: true));
      case FailureResult<void, Failure>(:final failure):
        emit(state.copyWith(status: AuthStatus.failure, failure: failure));
    }
  }

  void _onErrorCleared(AuthErrorCleared event, Emitter<AuthState> emit) {
    emit(state.copyWith(clearFailure: true));
  }

  void _handleAuthResult(Result<AuthUser, Failure> result, Emitter<AuthState> emit) {
    switch (result) {
      case Success<AuthUser, Failure>(:final data):
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: data,
            clearFailure: true,
            passwordResetEmailSent: false,
          ),
        );
      case FailureResult<AuthUser, Failure>(:final failure):
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            failure: failure,
            passwordResetEmailSent: false,
          ),
        );
    }
  }
}
