import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';

class GetCallSessionUseCase {
  final CallRepository _repository;

  const GetCallSessionUseCase(this._repository);

  Future<CallSession> call({required String callId, required String userId}) {
    return _repository.getCallSession(callId: callId, userId: userId);
  }
}
