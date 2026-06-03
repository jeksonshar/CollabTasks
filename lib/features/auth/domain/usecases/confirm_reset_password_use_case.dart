import 'package:collab_tasks/features/auth/domain/failures/failure.dart';
import 'package:collab_tasks/features/auth/domain/repositories/cognito_auth_repository.dart';
import 'package:collab_tasks/features/auth/domain/result/result.dart';

class ConfirmResetPasswordUseCase {
  ConfirmResetPasswordUseCase(this._repository);

  final CognitoAuthRepository? _repository;

  Future<Result<void, Failure>> call({
    required String email,
    required String code,
    required String newPassword,
  }) {
    if (_repository == null) {
      return Future.value(
        const FailureResult(
          OperationNotAllowedFailure('Confirm reset password is not supported for this backend.'),
        ),
      );
    }
    return _repository.confirmResetPassword(email: email, code: code, newPassword: newPassword);
  }
}
