import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:flutter/material.dart';

class ParticipantAvatar extends StatelessWidget {
  const ParticipantAvatar({super.key, required this.participant});

  final GroupParticipant participant;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = participant.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(avatarUrl));
    }
    return CircleAvatar(child: Text(participant.initials));
  }
}
