import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:collab_tasks/features/auth/domain/failures/failure.dart';
import 'package:collab_tasks/features/auth/domain/result/result.dart';

abstract class AuthRepository {
  Stream<AuthUser?> watchAuthState();

  Future<Result<AuthUser, Failure>> registerWithEmail({
    required String email,
    required String password,
  });

  Future<Result<AuthUser, Failure>> loginWithEmail({
    required String email,
    required String password,
  });

  Future<Result<AuthUser, Failure>> signInWithGoogle();

  Future<Result<void, Failure>> resetPassword({required String email});

  Future<Result<void, Failure>> confirmResetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<Result<void, Failure>> confirmSignUp({required String email, required String code});

  Future<Result<void, Failure>> resendSignUpCode({required String email});

  Future<Result<void, Failure>> logOut();
}
