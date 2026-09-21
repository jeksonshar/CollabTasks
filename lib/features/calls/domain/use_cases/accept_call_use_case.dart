import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';

class AcceptCallUseCase {
  final CallRepository _repository;

  const AcceptCallUseCase(this._repository);

  Future<void> call({required String callId, required String userId}) {
    return _repository.acceptCall(callId: callId, userId: userId);
  }
}
