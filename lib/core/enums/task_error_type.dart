import 'package:collab_tasks/l10n/app_localizations.dart';

enum TaskErrorType { load, add, update, delete }

extension TaskErrorTypeX on TaskErrorType {
  String label(AppLocalizations localization) {
    switch (this) {
      case TaskErrorType.load:
        return localization.loadTasksError;
      case TaskErrorType.add:
        return localization.addTaskError;
      case TaskErrorType.update:
        return localization.updateTaskError;
      case TaskErrorType.delete:
        return localization.deleteTaskError;
    }
  }
}
