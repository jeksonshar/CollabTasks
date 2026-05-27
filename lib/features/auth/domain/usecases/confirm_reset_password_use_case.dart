import 'package:collab_tasks/features/auth/domain/failures/failure.dart';
import 'package:collab_tasks/features/auth/domain/repositories/auth_repository.dart';
import 'package:collab_tasks/features/auth/domain/result/result.dart';

class ConfirmResetPasswordUseCase {
  ConfirmResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void, Failure>> call({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return _repository.confirmResetPassword(email: email, code: code, newPassword: newPassword);
  }
}
