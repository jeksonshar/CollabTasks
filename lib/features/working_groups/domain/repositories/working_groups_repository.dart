import 'package:collab_tasks/features/tasks/domain/models/task_draft.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';

abstract class WorkingGroupsRepository {
  Stream<List<WorkingGroup>> watchGroups();

  /// Принудительно загружает группы с удалённого источника и сохраняет в локальный кэш.
  Future<void> syncGroups();

  /// Принудительно загружает детали конкретной группы (участников и задачи) с удалённого источника и сохраняет в локальный кэш.
  Future<void> syncGroup(String groupId);

  Stream<WorkingGroup?> watchGroup(String groupId);

  Stream<List<GroupParticipant>> watchParticipants(String groupId);

  Stream<List<GroupTask>> watchGroupTasks(String groupId);

  Future<WorkingGroup> createGroup({required String title, required String description});

  Future<void> updateGroup(WorkingGroup group);

  Future<void> deleteGroup(String groupId);

  Future<void> inviteParticipantByEmail({required String groupId, required String email});

  Future<bool> hasActiveAssignedTasks({
    required String groupId,
    required String userId,
    required String userEmail,
  });

  Future<void> leaveGroup(String groupId);

  Future<void> addGroupTask({required String groupId, required TaskDraft draft});

  Future<void> updateGroupTask(GroupTask task);

  Future<GroupTask> claimGroupTask({required String groupId, required String taskId});

  Future<GroupTask> releaseGroupTask({required String groupId, required String taskId});

  void clearSubscriptions();
}
