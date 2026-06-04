import 'dart:async';

import 'package:collab_tasks/features/auth/data/models/auth_user_model.dart';
import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:collab_tasks/features/auth/domain/failures/failure.dart';
import 'package:collab_tasks/features/auth/domain/repositories/auth_repository.dart';
import 'package:collab_tasks/features/auth/domain/result/result.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthRepositoryImpl implements AuthRepository {
  FirebaseAuthRepositoryImpl({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    this.requireEmailVerifiedForEmailLogin = false,
  }) : _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn;

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final bool requireEmailVerifiedForEmailLogin;
  bool _isGoogleSignInInitialized = false;

  @override
  Stream<AuthUser?> watchAuthState() {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;

      // If strict validation is enabled and the email address isn't verified,
      // we do NOT signOut() here, we simply hide the user from the UI.
      if (requireEmailVerifiedForEmailLogin && !user.emailVerified) {
        return null;
      }

      return AuthUserModel.fromFirebaseUser(user);
    });
  }

  @override
  Future<Result<AuthUser, Failure>> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;

      if (user == null) {
        return const FailureResult(UnknownAuthFailure());
      }

      // First, we send a letter while the session is still active.
      await user.sendEmailVerification();

      // Log out to reset Firebase automatic login
      await _firebaseAuth.signOut();

      // We return a controlled error, which BLoC will handle and display "Check your mail"
      return const FailureResult(EmailNotVerifiedSentFailure());
    } on firebase_auth.FirebaseAuthException catch (exception) {
      // Just in case, we clear the session whenever an error occurs.
      await _firebaseAuth.signOut();
      return FailureResult(_mapFirebaseException(exception));
    } catch (_) {
      await _firebaseAuth.signOut();
      return const FailureResult(UnknownAuthFailure());
    }
  }

  @override
  Future<Result<AuthUser, Failure>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;

      if (user == null) {
        return const FailureResult(UnknownAuthFailure());
      }

      if (requireEmailVerifiedForEmailLogin) {
        // We update the user's status from the server to check emailVerified
        await user.reload();

        // We take a fresh instance after reloading
        final freshUser = _firebaseAuth.currentUser;

        if (freshUser == null || !freshUser.emailVerified) {
          await _firebaseAuth.signOut();
          return const FailureResult(EmailNotVerifiedConfirmEmailFailure());
        }

        return Success(AuthUserModel.fromFirebaseUser(freshUser));
      }

      return Success(AuthUserModel.fromFirebaseUser(user));
    } on firebase_auth.FirebaseAuthException catch (exception) {
      await _firebaseAuth.signOut();
      return FailureResult(_mapFirebaseException(exception));
    } catch (_) {
      await _firebaseAuth.signOut();
      return const FailureResult(UnknownAuthFailure());
    }
  }

  @override
  Future<Result<AuthUser, Failure>> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = firebase_auth.GoogleAuthProvider();
        final userCredential = await _firebaseAuth.signInWithPopup(provider);
        final user = userCredential.user;
        if (user == null) {
          return const FailureResult(UnknownAuthFailure());
        }
        return Success(AuthUserModel.fromFirebaseUser(user));
      }

      bool isLegacyAndroid = false;

      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          isLegacyAndroid = androidInfo.version.sdkInt < 35;
        } catch (e) {
          isLegacyAndroid = true;
        }
      }

      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          isLegacyAndroid) {
        final provider = firebase_auth.GoogleAuthProvider();
        try {
          final userCredential = await _firebaseAuth.signInWithProvider(provider);
          final user = userCredential.user;
          if (user == null) {
            return const FailureResult(UnknownAuthFailure());
          }
          return Success(AuthUserModel.fromFirebaseUser(user));
        } on firebase_auth.FirebaseAuthException catch (e) {
          // Fallback to google_sign_in below when native provider flow
          // is unavailable in current environment.
          return FailureResult(_mapFirebaseException(e));
        }
      }

      if (!_isGoogleSignInInitialized) {
        final options = Firebase.app().options;
        await _googleSignIn.initialize(
          serverClientId: options.androidClientId ?? options.iosClientId,
        );
        _isGoogleSignInInitialized = true;
      }

      if (!_googleSignIn.supportsAuthenticate()) {
        final provider = firebase_auth.GoogleAuthProvider();
        final userCredential = await _firebaseAuth.signInWithProvider(provider);
        final user = userCredential.user;
        if (user == null) {
          return const FailureResult(UnknownAuthFailure());
        }
        return Success(AuthUserModel.fromFirebaseUser(user));
      }

      final googleUser = await _googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        return const FailureResult(GoogleSignInNotSupportedFailure());
      }

      final credential = firebase_auth.GoogleAuthProvider.credential(idToken: googleAuth.idToken);

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        return const FailureResult(UnknownAuthFailure());
      }

      return Success(AuthUserModel.fromFirebaseUser(user));
    } on firebase_auth.FirebaseAuthException catch (exception) {
      return FailureResult(_mapFirebaseException(exception));
    } on GoogleSignInException catch (exception) {
      return FailureResult(_mapGoogleSignInException(exception));
    } catch (_) {
      return const FailureResult(UnknownAuthFailure());
    }
  }

  @override
  Future<Result<void, Failure>> resetPassword({required String email}) async {
    try {
      debugPrint('Auth.resetPassword: request started for email=$email');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      debugPrint('Auth.resetPassword: Firebase accepted request for email=$email');
      return const Success(null);
    } on firebase_auth.FirebaseAuthException catch (exception) {
      debugPrint(
        'Auth.resetPassword: FirebaseAuthException code=${exception.code}, message=${exception.message}',
      );
      return FailureResult(_mapFirebaseException(exception));
    } catch (_) {
      debugPrint('Auth.resetPassword: unknown error');
      return const FailureResult(UnknownAuthFailure());
    }
  }

  @override
  Future<Result<void, Failure>> logOut() async {
    try {
      // 1. We clear the native Google session ONLY on mobile devices.
      // On the web, this will throw an error if the login was via a Firebase Popup.
      if (!kIsWeb) {
        await _googleSignIn.signOut().timeout(
          const Duration(seconds: 3),
          onTimeout: () => null, // If the native SDK freezes, just move on.
        );
      }
    } catch (e) {
      // Ignore google_sign_in errors, as the main goal is to reset Firebase.
      debugPrint('Google SignOut ignored error: $e');
    }

    try {
      // 2. Resetting the main Firebase session
      await _firebaseAuth.signOut();
      return const Success(null);
    } on firebase_auth.FirebaseAuthException catch (exception) {
      return FailureResult(_mapFirebaseException(exception));
    } catch (error, stackTrace) {
      debugPrint('Firebase SignOut critical error: $error\n$stackTrace');
      return const FailureResult(UnknownAuthFailure());
    }
  }

  Failure _mapFirebaseException(firebase_auth.FirebaseAuthException exception) {
    switch (exception.code) {
      case 'wrong-password':
        return const WrongPasswordFailure();
      case 'user-not-found':
        return const UserNotFoundFailure();
      case 'network-request-failed':
        return const NetworkFailure();
      case 'action-code-expired':
        return const ActionCodeExpiredFailure();
      case 'email-already-in-use':
        return const EmailAlreadyInUseFailure();
      case 'invalid-email':
        return const InvalidEmailFailure();
      case 'weak-password':
        return const WeakPasswordFailure();
      case 'too-many-requests':
        return const TooManyRequestsFailure();
      case 'user-disabled':
        return const UserDisabledFailure();
      case 'invalid-credential':
      case 'account-exists-with-different-credential':
      case 'credential-already-in-use':
        return const InvalidCredentialFailure();
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'auth/popup-closed-by-user':
      case 'canceled':
      case 'sign_in_canceled':
      case 'abort':
      case 'acct_cancelled':
      case 'web-context-canceled':
        return const CanceledByUserFailure();
      case 'operation-not-allowed':
        return const OperationNotAllowedFailure();
      default:
        return UnknownAuthFailure(exception.message ?? 'Unknown authentication error.');
    }
  }

  Failure _mapGoogleSignInException(GoogleSignInException exception) {
    switch (exception.code) {
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.interrupted:
        return const CanceledByUserFailure();
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
      case GoogleSignInExceptionCode.uiUnavailable:
      case GoogleSignInExceptionCode.userMismatch:
      case GoogleSignInExceptionCode.unknownError:
        return UnknownAuthFailure(exception.description ?? 'Google Sign-In failed.');
    }
  }
}
