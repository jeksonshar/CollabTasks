import 'package:collab_tasks/features/auth/domain/failures/failure.dart';
import 'package:collab_tasks/features/auth/domain/repositories/auth_repository.dart';
import 'package:collab_tasks/features/auth/domain/result/result.dart';

class LogOutUseCase {
  LogOutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void, Failure>> call() {
    return _repository.logOut();
  }
}
