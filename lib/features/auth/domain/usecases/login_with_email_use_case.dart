import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:collab_tasks/features/auth/domain/failures/failure.dart';
import 'package:collab_tasks/features/auth/domain/repositories/auth_repository.dart';
import 'package:collab_tasks/features/auth/domain/result/result.dart';

class LoginWithEmailUseCase {
  LoginWithEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser, Failure>> call({required String email, required String password}) {
    return _repository.loginWithEmail(email: email, password: password);
  }
}
