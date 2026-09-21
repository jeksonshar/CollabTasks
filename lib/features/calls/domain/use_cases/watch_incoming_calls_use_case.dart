import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';

class WatchIncomingCallsUseCase {
  final CallRepository _repository;

  const WatchIncomingCallsUseCase(this._repository);

  Stream<List<Call>> call(String userId) {
    return _repository.watchIncomingCalls(userId);
  }
}
