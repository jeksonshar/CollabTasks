import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';

class StartCallUseCase {
  final CallRepository _repository;

  const StartCallUseCase(this._repository);

  Future<Call> call({
    String? callId,
    required String callerId,
    required String callerName,
    String? callerAvatarUrl,
    required List<String> calleeIds,
    required CallType type,
    bool isGroup = false,
    String? groupId,
  }) {
    return _repository.startCall(
      callId: callId,
      callerId: callerId,
      callerName: callerName,
      callerAvatarUrl: callerAvatarUrl,
      calleeIds: calleeIds,
      type: type,
      isGroup: isGroup,
      groupId: groupId,
    );
  }
}
