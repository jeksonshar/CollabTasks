import 'package:collab_tasks/features/working_groups/domain/repositories/working_groups_repository.dart';

class InviteGroupParticipantUseCase {
  const InviteGroupParticipantUseCase(this._repository);

  final WorkingGroupsRepository _repository;

  Future<void> call({required String groupId, required String email}) {
    return _repository.inviteParticipantByEmail(groupId: groupId, email: email);
  }
}
