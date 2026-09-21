import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';

class LeaveCallUseCase {
  final CallRepository _repository;

  const LeaveCallUseCase(this._repository);

  Future<void> call({required String callId, required String userId}) {
    return _repository.leaveCall(callId: callId, userId: userId);
  }
}
