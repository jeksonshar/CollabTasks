import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';

class InviteParticipantUseCase {
  final CallRepository _repository;

  const InviteParticipantUseCase(this._repository);

  Future<void> call({
    required String callId,
    required String userId,
    required String displayName,
    String? avatarUrl,
  }) {
    return _repository.inviteParticipant(
      callId: callId,
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }
}
