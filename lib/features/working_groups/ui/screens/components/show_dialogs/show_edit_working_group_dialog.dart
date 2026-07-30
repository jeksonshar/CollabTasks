import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_bloc.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_event.dart';
import 'package:collab_tasks/features/working_groups/ui/dialogs/edit_group_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showEditGroupDialog(BuildContext context, WorkingGroup group) async {
  final bloc = context.read<GroupDetailsBloc>();
  final result = await showDialog<EditGroupResult>(
    context: context,
    builder: (_) => EditGroupDialog(group: group),
  );

  if (result != null && context.mounted) {
    bloc.add(
      WorkingGroupUpdated(
        group.copyWith(
          title: result.title,
          description: result.description,
          avatarUrl: result.avatarUrl,
        ),
      ),
    );
  }
}
