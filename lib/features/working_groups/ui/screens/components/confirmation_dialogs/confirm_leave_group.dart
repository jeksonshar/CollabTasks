import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_bloc.dart';
import 'package:collab_tasks/features/working_groups/ui/blocs/working_group_details/group_details_event.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> confirmLeaveGroup(BuildContext context) async {
  final localization = AppLocalizations.of(context)!;
  final bloc = context.read<GroupDetailsBloc>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(localization.group_details_leaveGroupTitle),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(localization.group_details_cancelBtn),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(localization.group_details_leaveGroupBtn),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    bloc.add(const WorkingGroupLeft());
  }
}
