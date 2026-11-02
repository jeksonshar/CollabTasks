import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';

class UpdateCallHeartbeatUseCase {
  final CallRepository _repository;

  const UpdateCallHeartbeatUseCase(this._repository);

  Future<void> call({required String callId, required String userId}) {
    return _repository.updateParticipantHeartbeat(callId: callId, userId: userId);
  }
}
