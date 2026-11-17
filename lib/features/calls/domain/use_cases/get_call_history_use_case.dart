import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';

class GetCallHistoryUseCase {
  final CallRepository _repository;

  const GetCallHistoryUseCase(this._repository);

  Future<CallHistoryPage> call({
    required String currentUserId,
    required int pageSize,
    String? groupId,
    String? opponentId,
    CallHistoryCursor? cursor,
  }) {
    return _repository.getCallHistoryPage(
      currentUserId: currentUserId,
      pageSize: pageSize,
      groupId: groupId,
      opponentId: opponentId,
      cursor: cursor,
    );
  }
}
