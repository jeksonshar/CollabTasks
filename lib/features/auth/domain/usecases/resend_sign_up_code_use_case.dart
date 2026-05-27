import 'package:collab_tasks/features/auth/domain/failures/failure.dart';
import 'package:collab_tasks/features/auth/domain/repositories/auth_repository.dart';
import 'package:collab_tasks/features/auth/domain/result/result.dart';

class ResendSignUpCodeUseCase {
  ResendSignUpCodeUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void, Failure>> call({required String email}) {
    return _repository.resendSignUpCode(email: email);
  }
}
