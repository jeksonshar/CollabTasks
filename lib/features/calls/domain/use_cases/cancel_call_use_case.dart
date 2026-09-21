import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';

class CancelCallUseCase {
  final CallRepository _repository;

  const CancelCallUseCase(this._repository);

  Future<void> call(String callId) {
    return _repository.cancelCall(callId);
  }
}
