import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';

class GetCallHistoryUseCase {
  final CallRepository _repository;

  const GetCallHistoryUseCase(this._repository);

  Future<List<Call>> call({required String currentUserId, String? groupId, String? opponentId}) {
    return _repository.getCallHistory(
      currentUserId: currentUserId,
      groupId: groupId,
      opponentId: opponentId,
    );
  }
}
