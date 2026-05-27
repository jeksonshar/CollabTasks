import 'package:collab_tasks/core/utils/auth_utils.dart';
import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:collab_tasks/features/auth/domain/failures/failure.dart';
import 'package:collab_tasks/features/auth/domain/result/result.dart';
import 'package:collab_tasks/features/auth/domain/usecases/confirm_reset_password_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/confirm_sign_up_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/log_out_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/login_with_email_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/register_with_email_use_case.dart';
import 'package:collab_tasks/features/auth/domain/usecases/resend_sign_up_code_use_case.dart';
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
    required ConfirmSignUpUseCase confirmSignUpUseCase,
    required ConfirmResetPasswordUseCase confirmResetPasswordUseCase,
    required ResendSignUpCodeUseCase resendSignUpCodeUseCase,
    required LogOutUseCase logOutUseCase,
    required WatchAuthStateUseCase watchAuthStateUseCase,
  }) : _registerWithEmailUseCase = registerWithEmailUseCase,
       _loginWithEmailUseCase = loginWithEmailUseCase,
       _signInWithGoogleUseCase = signInWithGoogleUseCase,
       _resetPasswordUseCase = resetPasswordUseCase,
       _confirmSignUpUseCase = confirmSignUpUseCase,
       _confirmResetPasswordUseCase = confirmResetPasswordUseCase,
       _resendSignUpCodeUseCase = resendSignUpCodeUseCase,
       _logOutUseCase = logOutUseCase,
       _watchAuthStateUseCase = watchAuthStateUseCase,
       super(const AuthState()) {
    on<AuthSubscriptionStarted>(_onSubscriptionStarted);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthConfirmResetPasswordRequested>(_onConfirmResetPasswordRequested);
    on<AuthConfirmSignUpRequested>(_onConfirmSignUpRequested);
    on<AuthResendSignUpCodeRequested>(_onResendSignUpCodeRequested);
    on<AuthLogOutRequested>(_onLogOutRequested);
    on<AuthErrorCleared>(_onErrorCleared);
  }

  final RegisterWithEmailUseCase _registerWithEmailUseCase;
  final LoginWithEmailUseCase _loginWithEmailUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final ConfirmSignUpUseCase _confirmSignUpUseCase;
  final ConfirmResetPasswordUseCase _confirmResetPasswordUseCase;
  final ResendSignUpCodeUseCase _resendSignUpCodeUseCase;
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
            signUpCodeResent: false,
            signUpConfirmed: false,
            requiresSignUpConfirmation: false,
            clearPendingConfirmationEmail: true,
            requiresResetPasswordConfirmation: false,
            clearPendingResetPasswordEmail: true,
            passwordResetConfirmed: false,
          );
        }

        return state.copyWith(status: AuthStatus.authenticated, user: user, clearFailure: true);
      },
      onError: (_, _) => state.copyWith(status: AuthStatus.failure),
    );
  }

  Future<void> _onRegisterRequested(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(
      state.copyWith(
        status: AuthStatus.loadingBeforeStart,
        clearFailure: true,
        signUpCodeResent: false,
        signUpConfirmed: false,
        requiresSignUpConfirmation: false,
        clearPendingConfirmationEmail: true,
        requiresResetPasswordConfirmation: false,
        clearPendingResetPasswordEmail: true,
        passwordResetConfirmed: false,
      ),
    );

    final result = await _registerWithEmailUseCase(email: event.email, password: event.password);

    _handleAuthResult(result, emit, attemptedEmail: event.email);
  }

  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loadingFormSubmit, clearFailure: true));

    final result = await _loginWithEmailUseCase(email: event.email, password: event.password);

    _handleAuthResult(result, emit, attemptedEmail: event.email);
  }

  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loadingFormSubmit, clearFailure: true));
    final result = await _signInWithGoogleUseCase();
    _handleAuthResult(result, emit);
  }

  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loadingFormSubmit,
        clearFailure: true,
        passwordResetEmailSent: false,
        passwordResetConfirmed: false,
      ),
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
            passwordResetConfirmed: false,
            signUpCodeResent: false,
            signUpConfirmed: false,
            requiresSignUpConfirmation: false,
            clearPendingConfirmationEmail: true,
            requiresResetPasswordConfirmation: authBackend == AuthBackend.aws,
            pendingResetPasswordEmail: authBackend == AuthBackend.aws ? event.email : null,
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
            signUpCodeResent: false,
            signUpConfirmed: false,
            requiresSignUpConfirmation: false,
            clearPendingConfirmationEmail: true,
            requiresResetPasswordConfirmation: false,
            clearPendingResetPasswordEmail: true,
            passwordResetConfirmed: false,
          ),
        );
    }
  }

  Future<void> _onConfirmResetPasswordRequested(
    AuthConfirmResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loadingFormSubmit,
        clearFailure: true,
        passwordResetConfirmed: false,
      ),
    );

    final result = await _confirmResetPasswordUseCase(
      email: event.email,
      code: event.code,
      newPassword: event.newPassword,
    );

    switch (result) {
      case Success<void, Failure>():
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearFailure: true,
            passwordResetEmailSent: false,
            requiresResetPasswordConfirmation: false,
            clearPendingResetPasswordEmail: true,
            passwordResetConfirmed: true,
          ),
        );
      case FailureResult<void, Failure>(:final failure):
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            failure: failure,
            passwordResetConfirmed: false,
          ),
        );
    }
  }

  Future<void> _onConfirmSignUpRequested(
    AuthConfirmSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loadingFormSubmit,
        clearFailure: true,
        signUpCodeResent: false,
        signUpConfirmed: false,
        requiresSignUpConfirmation: true,
        pendingConfirmationEmail: event.email,
      ),
    );

    final result = await _confirmSignUpUseCase(email: event.email, code: event.code);
    switch (result) {
      case Success<void, Failure>():
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearFailure: true,
            signUpConfirmed: true,
            signUpCodeResent: false,
            requiresSignUpConfirmation: false,
            clearPendingConfirmationEmail: true,
            requiresResetPasswordConfirmation: false,
            clearPendingResetPasswordEmail: true,
            passwordResetConfirmed: false,
          ),
        );
      case FailureResult<void, Failure>(:final failure):
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            failure: failure,
            signUpConfirmed: false,
            signUpCodeResent: false,
            requiresSignUpConfirmation: true,
            pendingConfirmationEmail: event.email,
          ),
        );
    }
  }

  Future<void> _onResendSignUpCodeRequested(
    AuthResendSignUpCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loadingFormSubmit,
        clearFailure: true,
        signUpCodeResent: false,
        signUpConfirmed: false,
        requiresSignUpConfirmation: true,
        pendingConfirmationEmail: event.email,
      ),
    );

    final result = await _resendSignUpCodeUseCase(email: event.email);
    switch (result) {
      case Success<void, Failure>():
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearFailure: true,
            signUpCodeResent: true,
            signUpConfirmed: false,
            requiresSignUpConfirmation: true,
            pendingConfirmationEmail: event.email,
          ),
        );
      case FailureResult<void, Failure>(:final failure):
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            failure: failure,
            signUpCodeResent: false,
            signUpConfirmed: false,
            requiresSignUpConfirmation: true,
            pendingConfirmationEmail: event.email,
          ),
        );
    }
  }

  Future<void> _onLogOutRequested(AuthLogOutRequested event, Emitter<AuthState> emit) async {
    // Переводим в лоадинг, чтобы показать вертушку на кнопке/экране
    emit(state.copyWith(status: AuthStatus.loadingFormSubmit, clearFailure: true));

    final result = await _logOutUseCase();

    switch (result) {
      case Success<void, Failure>():
        // ВАЖНО: Мы БОЛЬШЕ НЕ ЭМИТИМ AuthStatus.unauthenticated здесь вручную!
        // Стрим _onSubscriptionStarted сам получит null из Amplify,
        // очистит юзера и выдаст РОВНО ОДИН стейт unauthenticated на всё приложение.
        break;

      case FailureResult<void, Failure>(:final failure):
        emit(state.copyWith(status: AuthStatus.failure, failure: failure));
    }
  }

  void _onErrorCleared(AuthErrorCleared event, Emitter<AuthState> emit) {
    emit(state.copyWith(clearFailure: true));
  }

  void _handleAuthResult(
    Result<AuthUser, Failure> result,
    Emitter<AuthState> emit, {
    String? attemptedEmail,
  }) {
    switch (result) {
      case Success<AuthUser, Failure>():
        // ВАЖНО: Мы БОЛЬШЕ НЕ ЭМИТИМ AuthStatus.authenticated здесь!
        // Мы просто переводим статус в unauthenticated (или оставляем как есть),
        // потому что стрим _watchAuthStateUseCase() сам поймает юзера и чисто переведет статус в authenticated.
        // Это убирает гонку состояний.
        break;

      case FailureResult<AuthUser, Failure>(:final failure):
        if (failure is EmailNotVerifiedFailure) {
          if (authBackend == AuthBackend.firebase) {
            emit(
              state.copyWith(
                status: AuthStatus.unauthenticated,
                failure: failure,
                passwordResetEmailSent: false,
                signUpCodeResent: false,
                signUpConfirmed: false,
                requiresSignUpConfirmation: false,
                clearPendingConfirmationEmail: true,
                requiresResetPasswordConfirmation: false,
                clearPendingResetPasswordEmail: true,
                passwordResetConfirmed: false,
              ),
            );
            return;
          }
          emit(
            state.copyWith(
              status: AuthStatus.unauthenticated,
              failure: failure,
              passwordResetEmailSent: false,
              signUpCodeResent: false,
              signUpConfirmed: false,
              requiresSignUpConfirmation: true,
              pendingConfirmationEmail: attemptedEmail ?? state.pendingConfirmationEmail,
              requiresResetPasswordConfirmation: false,
              clearPendingResetPasswordEmail: true,
              passwordResetConfirmed: false,
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            failure: failure,
            passwordResetEmailSent: false,
            signUpCodeResent: false,
            signUpConfirmed: false,
            requiresSignUpConfirmation: false,
            clearPendingConfirmationEmail: true,
            requiresResetPasswordConfirmation: false,
            clearPendingResetPasswordEmail: true,
            passwordResetConfirmed: false,
          ),
        );
    }
  }
}
