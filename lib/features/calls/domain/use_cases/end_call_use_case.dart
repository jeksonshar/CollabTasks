import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';

class EndCallUseCase {
  final CallRepository _repository;

  const EndCallUseCase(this._repository);

  Future<void> call(String callId) {
    return _repository.endCall(callId);
  }
}
