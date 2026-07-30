import 'package:collab_tasks/features/tasks/ui/dialogs/task_dialog/task_dialog.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_bloc.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showAddGroupDialog(BuildContext context) async {
  final bloc = context.read<GroupDetailsBloc>();
  final draft = await showDialog(context: context, builder: (_) => const TaskDialog());
  if (draft != null && context.mounted) {
    bloc.add(GroupTaskAdded(draft));
  }
}
