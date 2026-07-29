import 'dart:async';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart' as domain;
import 'package:collab_tasks/features/auth/domain/failures/failure.dart';
import 'package:collab_tasks/features/auth/domain/repositories/auth_repository.dart';
import 'package:collab_tasks/features/auth/domain/repositories/cognito_auth_repository.dart';
import 'package:collab_tasks/features/auth/domain/result/result.dart';
import 'package:flutter/cupertino.dart';

class AwsAuthRepositoryImpl implements AuthRepository, CognitoAuthRepository {
  AwsAuthRepositoryImpl({this.requireEmailVerifiedForEmailLogin = false});

  final bool requireEmailVerifiedForEmailLogin;

  @override
  Stream<domain.AuthUser?> watchAuthState() {
    return Stream<domain.AuthUser?>.multi((multi) {
      final subscription = Amplify.Hub.listen(HubChannel.Auth, (_) async {
        multi.add(await _getCurrentUserOrNull());
      });

      multi
        ..addStream(Stream.fromFuture(_getCurrentUserOrNull()))
        ..onCancel = () async {
          await subscription.cancel();
        };
    });
  }

  @override
  Future<Result<domain.AuthUser, Failure>> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final signUpResult = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(userAttributes: {AuthUserAttributeKey.email: email}),
      );

      if (!signUpResult.isSignUpComplete) {
        return const FailureResult(EmailNotVerifiedConfirmEmailFailure());
      }

      final signInResult = await Amplify.Auth.signIn(username: email, password: password);

      if (!signInResult.isSignedIn) {
        return FailureResult(_mapSignInNextStepToFailure(signInResult.nextStep));
      }

      final user = await _getCurrentUserOrNull();
      if (user == null) {
        return const FailureResult(UnknownAuthFailure());
      }

      return Success(user);
    } on AuthException catch (exception) {
      return FailureResult(_mapAuthException(exception));
    } catch (_) {
      return const FailureResult(UnknownAuthFailure());
    }
  }

  @override
  Future<Result<domain.AuthUser, Failure>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.signIn(username: email, password: password);

      if (!result.isSignedIn) {
        return FailureResult(_mapSignInNextStepToFailure(result.nextStep));
      }

      final user = await _getCurrentUserOrNull();
      if (user == null) {
        return const FailureResult(UnknownAuthFailure());
      }

      if (requireEmailVerifiedForEmailLogin && !user.isEmailVerified) {
        await Amplify.Auth.signOut();
        return const FailureResult(EmailNotVerifiedFailure());
      }

      return Success(user);
    } on AuthException catch (exception) {
      return FailureResult(_mapAuthException(exception));
    } catch (_) {
      return const FailureResult(UnknownAuthFailure());
    }
  }

  @override
  Future<Result<domain.AuthUser, Failure>> signInWithGoogle() async {
    try {
      // We invoke authorization through the Google provider.
      // Amplify will automatically open the Hosted UI browser.
      debugPrint('signInWithGoogle() 0 started');
      final result = await Amplify.Auth.signInWithWebUI(provider: AuthProvider.google);
      debugPrint('signInWithGoogle() 1 result = $result');
      // Checking if the login was successful
      if (!result.isSignedIn) {
        return FailureResult(
          UnknownAuthFailure(
            result.nextStep.additionalInfo['message'] ??
                'Google Sign-In via AWS WebUI did not complete.',
          ),
        );
      }

      // We retrieve the current user's data (the session is already active)
      final user = await _getCurrentUserOrNull();
      debugPrint('signInWithGoogle() 2 user = $user');
      if (user == null) {
        return const FailureResult(UnknownAuthFailure());
      }

      return Success(user);
    } on UserCancelledException {
      // We catch a specific cancellation exception directly!
      return const FailureResult(CanceledByUserFailure());
    } on AuthException catch (exception) {
      return FailureResult(_mapAuthException(exception));
    } catch (_) {
      return const FailureResult(UnknownAuthFailure());
    }
  }

  @override
  Future<Result<void, Failure>> resetPassword({required String email}) async {
    try {
      final result = await Amplify.Auth.resetPassword(username: email);
      final step = result.nextStep.updateStep;

      if (step == AuthResetPasswordStep.confirmResetPasswordWithCode) {
        return const Success(null);
      }

      if (step == AuthResetPasswordStep.done) {
        return const FailureResult(ResetPasswordUnavailableFailure());
      }

      return const Success(null);
    } on AuthException catch (exception) {
      return FailureResult(_mapAuthException(exception));
    } catch (_) {
      return const FailureResult(UnknownAuthFailure());
    }
  }

  @override
  Future<Result<void, Failure>> confirmResetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: code,
      );
      return const Success(null);
    } on AuthException catch (exception) {
      return FailureResult(_mapAuthException(exception));
    } catch (_) {
      return const FailureResult(UnknownAuthFailure());
    }
  }

  @override
  Future<Result<void, Failure>> confirmSignUp({required String email, required String code}) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(username: email, confirmationCode: code);
      if (!result.isSignUpComplete) {
        return const FailureResult(ConfirmationNotCompleteFailure());
      }
      return const Success(null);
    } on AuthException catch (exception) {
      return FailureResult(_mapAuthException(exception));
    } catch (_) {
      return const FailureResult(UnknownAuthFailure());
    }
  }

  @override
  Future<Result<void, Failure>> resendSignUpCode({required String email}) async {
    try {
      await Amplify.Auth.resendSignUpCode(username: email);
      return const Success(null);
    } on AuthException catch (exception) {
      return FailureResult(_mapAuthException(exception));
    } catch (_) {
      return const FailureResult(UnknownAuthFailure());
    }
  }

  @override
  Future<Result<void, Failure>> logOut() async {
    try {
      await Amplify.Auth.signOut();
      return const Success(null);
    } on AuthException catch (exception) {
      return FailureResult(_mapAuthException(exception));
    } catch (_) {
      return const FailureResult(UnknownAuthFailure());
    }
  }

  Future<domain.AuthUser?> _getCurrentUserOrNull() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        return null;
      }

      final currentUser = await Amplify.Auth.getCurrentUser();
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final email = _attributeValue(attributes, AuthUserAttributeKey.email);
      final emailVerifiedRaw = _attributeValue(attributes, AuthUserAttributeKey.emailVerified);
      final emailVerified = emailVerifiedRaw?.toLowerCase() == 'true';

      // Dynamically determine the provider based on data from AWS Cognito
      final userIdLower = currentUser.userId.toLowerCase();
      final usernameLower = currentUser.username.toLowerCase();

      domain.AuthProviderType provider = domain.AuthProviderType.email;

      if (userIdLower.contains('google') || usernameLower.contains('google')) {
        provider = domain.AuthProviderType.google;
      }

      return domain.AuthUser(
        id: currentUser.userId,
        email: email ?? currentUser.username,
        isEmailVerified: emailVerified,
        displayName: _displayNameFromAttributes(attributes),
        provider: provider, // We pass a dynamically defined provider
      );
    } on AuthException {
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<domain.AuthUser?> getCurrentUser() async {
    final user = await _getCurrentUserOrNull();
    return user;
  }

  String? _attributeValue(List<AuthUserAttribute> attributes, AuthUserAttributeKey key) {
    for (final attribute in attributes) {
      if (attribute.userAttributeKey == key) {
        final value = attribute.value.trim();
        return value.isEmpty ? null : value;
      }
    }
    return null;
  }

  String? _displayNameFromAttributes(List<AuthUserAttribute> attributes) {
    final name = _attributeValue(attributes, AuthUserAttributeKey.name);
    if (name != null) {
      return name;
    }

    final givenName = _attributeValue(attributes, AuthUserAttributeKey.givenName);
    final familyName = _attributeValue(attributes, AuthUserAttributeKey.familyName);
    final fullName = [givenName, familyName].whereType<String>().join(' ').trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    return _attributeValue(attributes, AuthUserAttributeKey.preferredUsername);
  }

  Failure _mapAuthException(AuthException exception) {
    switch (exception.runtimeType.toString()) {
      case 'UsernameExistsException':
        return const EmailAlreadyInUseFailure();
      case 'InvalidPasswordException':
        return const WeakPasswordFailure();
      case 'UserNotFoundException':
        return const UserNotFoundFailure();
      case 'NotAuthorizedServiceException':
      case 'NotAuthorizedException':
        return const InvalidCredentialFailure();
      case 'UserNotConfirmedException':
        return const EmailNotVerifiedConfirmEmailFailure();
      case 'InvalidParameterException':
      case 'AliasExistsException':
        return const InvalidEmailFailure();
      case 'CodeExpiredException':
      case 'ExpiredCodeException':
        return const ActionCodeExpiredFailure();
      case 'LimitExceededException':
      case 'TooManyRequestsException':
        return const TooManyRequestsFailure();
      case 'NetworkException':
        return const NetworkFailure();
      case 'UserCancelledException':
        return const CanceledByUserFailure();
      default:
        debugPrint('_mapAuthException() error = $exception');
        return UnknownAuthFailure(exception.message);
    }
  }

  Failure _mapSignInNextStepToFailure(AuthNextSignInStep nextStep) {
    final step = nextStep.signInStep;

    if (step == AuthSignInStep.confirmSignUp) {
      return const EmailNotVerifiedConfirmEmailFailure();
    }

    if (step == AuthSignInStep.resetPassword) {
      return const PasswordResetRequiredFailure();
    }

    return UnknownAuthFailure(
      nextStep.additionalInfo['message'] ?? 'Sign-in requires additional steps.',
    );
  }
}
