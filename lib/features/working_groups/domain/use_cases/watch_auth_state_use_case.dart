import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:collab_tasks/features/auth/domain/repositories/auth_repository.dart';

class WatchAuthStateUseCase {
  final AuthRepository _authRepository;

  const WatchAuthStateUseCase(this._authRepository);

  /// Возвращает стрим с текущим состоянием пользователя (null, если не авторизован)
  Stream<AuthUser?> call() {
    return _authRepository.watchAuthState();
  }
}
