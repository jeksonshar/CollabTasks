import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';

class ReconcileStaleCallParticipantsUseCase {
  final CallRepository _repository;

  const ReconcileStaleCallParticipantsUseCase(this._repository);

  Future<List<String>> call({required String callId}) {
    return _repository.reconcileStaleCallParticipants(callId: callId);
  }
}
