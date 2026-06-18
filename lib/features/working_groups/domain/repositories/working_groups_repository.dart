import 'package:collab_tasks/features/tasks/domain/models/task_draft.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';

abstract class WorkingGroupsRepository {
  Stream<List<WorkingGroup>> watchGroups();

  Stream<List<GroupParticipant>> watchParticipants(String groupId);

  Stream<List<GroupTask>> watchGroupTasks(String groupId);

  Future<WorkingGroup> createGroup({required String title, required String description});

  Future<void> addGroupTask({required String groupId, required TaskDraft draft});

  Future<void> updateGroupTask(GroupTask task);

  Future<void> claimGroupTask({required String groupId, required String taskId});

  Future<void> releaseGroupTask({required String groupId, required String taskId});
}
