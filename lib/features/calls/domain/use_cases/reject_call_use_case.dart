import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';

class RejectCallUseCase {
  final CallRepository _repository;

  const RejectCallUseCase(this._repository);

  Future<void> call({required String callId, required String userId}) {
    return _repository.rejectCall(callId: callId, userId: userId);
  }
}
