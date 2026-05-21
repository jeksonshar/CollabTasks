# Auth Feature (`lib/features/auth`)

## Overview

Модуль авторизации построен по Clean Architecture:

- `domain/` — сущности, ошибки, `Result`, контракты репозитория, use cases.
- `data/` — модели и `FirebaseAuthRepositoryImpl` (Firebase + Google Sign-In).

`Domain` слой не зависит от Firebase SDK.

## Domain API

### Entity

- `AuthUser`:
  - `id`
  - `email`
  - `isEmailVerified`

### Result

- `Result<S, F>`:
  - `Success<S, F>(data)`
  - `FailureResult<S, F>(failure)`

### Failures

Базовый класс: `Failure(message)`.

Примеры:
- `WrongPasswordFailure`
- `UserNotFoundFailure`
- `NetworkFailure`
- `ActionCodeExpiredFailure`
- `EmailNotVerifiedFailure`
- `UnknownAuthFailure`

### Repository Contract

`AuthRepository`:

- `Stream<AuthUser?> watchAuthState()`
- `Future<Result<AuthUser, Failure>> registerWithEmail(...)`
- `Future<Result<AuthUser, Failure>> loginWithEmail(...)`
- `Future<Result<AuthUser, Failure>> signInWithGoogle()`
- `Future<Result<void, Failure>> resetPassword(...)`
- `Future<Result<void, Failure>> logOut()`

## Use Cases

- `RegisterWithEmailUseCase`
- `LoginWithEmailUseCase`
- `SignInWithGoogleUseCase`
- `ResetPasswordUseCase`
- `LogOutUseCase`
- `WatchAuthStateUseCase`

## DI Registration (GetIt)

Регистрируется в `lib/di/service_locator.dart`:

- `FirebaseAuth`
- `GoogleSignIn`
- `AuthRepository` -> `FirebaseAuthRepositoryImpl`
- все auth use cases
- `AuthBloc`

## Usage Example (BLoC + UI)

```dart
BlocProvider<AuthBloc>(
  create: (_) => getIt<AuthBloc>()..add(const AuthSubscriptionStarted()),
  child: BlocBuilder<AuthBloc, AuthState>(
    builder: (context, state) {
      if (state.status == AuthStatus.authenticated) {
        return const MainScreen();
      }
      return const AuthScreen();
    },
  ),
)
```

Пример Auth UI: `lib/ui/screens/auth_screen/auth_screen.dart`.
Пример Auth BLoC: `lib/ui/blocs/auth_bloc/`.
