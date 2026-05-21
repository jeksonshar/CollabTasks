import 'package:collab_tasks/features/auth/data/models/auth_user_model.dart';
import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:collab_tasks/features/auth/domain/failures/failure.dart';
import 'package:collab_tasks/features/auth/domain/repositories/auth_repository.dart';
import 'package:collab_tasks/features/auth/domain/result/result.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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
      if (user == null) {
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

      await user.sendEmailVerification();
      return Success(AuthUserModel.fromFirebaseUser(user));
    } on firebase_auth.FirebaseAuthException catch (exception) {
      return FailureResult(_mapFirebaseException(exception));
    } catch (_) {
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
      var user = credential.user;

      if (user == null) {
        return const FailureResult(UnknownAuthFailure());
      }

      if (requireEmailVerifiedForEmailLogin) {
        await user.reload();
        user = _firebaseAuth.currentUser;
        if (user == null) {
          return const FailureResult(UnknownAuthFailure());
        }

        if (!user.emailVerified) {
          await _firebaseAuth.signOut();
          return const FailureResult(EmailNotVerifiedFailure());
        }
      }

      return Success(AuthUserModel.fromFirebaseUser(user));
    } on firebase_auth.FirebaseAuthException catch (exception) {
      return FailureResult(_mapFirebaseException(exception));
    } catch (_) {
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

      if (!_isGoogleSignInInitialized) {
        await _googleSignIn.initialize();
        _isGoogleSignInInitialized = true;
      }

      final googleUser = await _googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;
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
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      return const Success(null);
    } on firebase_auth.FirebaseAuthException catch (exception) {
      return FailureResult(_mapFirebaseException(exception));
    } catch (_) {
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
