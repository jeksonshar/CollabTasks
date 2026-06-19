import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';

abstract class WorkingGroupsRemoteDataSource {
  Stream<List<WorkingGroup>> watchGroups({required String userId, required String userEmail});

  Stream<List<GroupParticipant>> watchParticipants({required String groupId});

  Stream<List<GroupTask>> watchTasks({required String groupId});

  Future<void> upsertGroup({
    required WorkingGroup group,
    List<String> participantUserIds,
    List<String> participantEmails,
  });

  Future<void> deleteGroup(String groupId);

  Future<void> inviteParticipantByEmail({required String groupId, required String email});

  Future<void> upsertParticipant(GroupParticipant participant);

  Future<void> upsertTask(GroupTask task);

  Future<void> deleteTask({required String groupId, required String taskId});

  Future<void> claimTask({
    required String groupId,
    required String taskId,
    required String participantId,
    required int updatedAt,
  });
}
