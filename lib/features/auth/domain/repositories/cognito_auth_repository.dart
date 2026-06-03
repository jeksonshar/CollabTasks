import 'package:collab_tasks/features/auth/domain/failures/failure.dart';

import 'package:collab_tasks/features/auth/domain/result/result.dart';

abstract class CognitoAuthRepository {
  Future<Result<void, Failure>> confirmResetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<Result<void, Failure>> confirmSignUp({required String email, required String code});

  Future<Result<void, Failure>> resendSignUpCode({required String email});
}
