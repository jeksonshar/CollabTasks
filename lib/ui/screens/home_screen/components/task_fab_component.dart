import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

FloatingActionButtonLocation get fabLocation => FloatingActionButtonLocation.endFloat;

class AddTaskFab extends StatelessWidget {
  final VoidCallback onPressed;

  const AddTaskFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return FloatingActionButton.extended(
      onPressed: onPressed,
      label: Text(localization.addTaskTitle),
      icon: const Icon(Icons.add),
    );
  }
}
