import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:collab_tasks/features/auth/domain/repositories/auth_repository.dart';

class WatchAuthStateUseCase {
  WatchAuthStateUseCase(this._repository);

  final AuthRepository _repository;

  Stream<AuthUser?> call() => _repository.watchAuthState();
}
