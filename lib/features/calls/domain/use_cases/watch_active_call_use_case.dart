import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';

class WatchActiveCallUseCase {
  final CallRepository _repository;

  const WatchActiveCallUseCase(this._repository);

  Stream<Call?> call(String callId) {
    return _repository.watchActiveCall(callId);
  }
}
