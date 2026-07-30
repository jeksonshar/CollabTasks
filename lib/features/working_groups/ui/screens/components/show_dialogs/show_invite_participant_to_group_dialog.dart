import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_bloc.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_event.dart';
import 'package:collab_tasks/features/working_groups/ui/dialogs/invite_participant_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showInviteDialog(BuildContext context) async {
  final bloc = context.read<GroupDetailsBloc>();
  final email = await showDialog<String>(
    context: context,
    builder: (_) => const InviteParticipantDialog(),
  );

  if (email != null && context.mounted) {
    bloc.add(GroupParticipantInvited(email));
  }
}
