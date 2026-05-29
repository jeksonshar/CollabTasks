import 'package:collab_tasks/features/auth/domain/failures/failure.dart';
import 'package:collab_tasks/features/auth/domain/repositories/cognito_auth_repository.dart';
import 'package:collab_tasks/features/auth/domain/result/result.dart';

class ResendSignUpCodeUseCase {
  ResendSignUpCodeUseCase(this._repository);

  final CognitoAuthRepository? _repository;

  Future<Result<void, Failure>> call({required String email}) {
    if (_repository == null) {
      return Future.value(
        const FailureResult(
          OperationNotAllowedFailure('Resend sign up code is not supported for this backend.'),
        ),
      );
    }
    return _repository.resendSignUpCode(email: email);
  }
}
