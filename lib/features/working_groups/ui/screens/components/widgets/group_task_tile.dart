import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/ui/screens/components/widgets/participant_avatar.dart';
import 'package:collab_tasks/features/working_groups/ui/screens/working_group_task_details_screen.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class GroupTaskTile extends StatelessWidget {
  const GroupTaskTile({
    super.key,
    required this.task,
    required this.assignee,
    required this.currentUserId,
    required this.participants,
  });

  final GroupTask task;
  final GroupParticipant? assignee;
  final String? currentUserId;
  final List<GroupParticipant> participants;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: assignee == null
            ? const CircleAvatar(child: Icon(Icons.lock_open))
            : ParticipantAvatar(participant: assignee!),
        title: Text(task.title),
        subtitle: Text(
          assignee == null
              ? localization.group_details_taskFree
              : localization.group_details_taskInWork(assignee!.name),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WorkingGroupTaskDetailsScreen(task: task, participants: participants),
            ),
          );
        },
      ),
    );
  }
}
