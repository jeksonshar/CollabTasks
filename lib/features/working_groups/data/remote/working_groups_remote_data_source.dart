import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';

abstract class WorkingGroupsRemoteDataSource {
  Stream<List<WorkingGroup>> watchGroups({required String userId, required String userEmail});

  /// Однократно получает актуальный список групп с сервера (без создания подписки).
  Future<List<WorkingGroup>> fetchGroups({required String userId, required String userEmail});

  Stream<List<GroupParticipant>> watchParticipants({required String groupId});

  Stream<List<GroupTask>> watchTasks({required String groupId});

  Future<void> upsertGroup({
    required WorkingGroup group,
    List<String> participantUserIds,
    List<String> participantEmails,
  });

  Future<void> deleteGroup(String groupId);

  Future<void> inviteParticipantByEmail({required String groupId, required String email});

  /// Whether [userId]/[userEmail] is still listed as a member of [groupId]
  /// according to the authoritative group record (its participant arrays).
  /// Used to avoid re-adding a user who has explicitly left the group.
  Future<bool> isGroupMember({
    required String groupId,
    required String userId,
    required String userEmail,
  });

  Future<void> upsertParticipant(GroupParticipant participant);

  Future<void> leaveGroup({
    required String groupId,
    required String userId,
    required String userEmail,
    required List<String> participantIds,
  });

  Future<void> upsertTask(GroupTask task);

  Future<void> deleteTask({required String groupId, required String taskId});

  Future<void> claimTask({
    required String groupId,
    required String taskId,
    required String participantId,
    required int updatedAt,
  });
}
