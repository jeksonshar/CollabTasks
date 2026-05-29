import 'package:collab_tasks/l10n/app_localizations.dart';

enum TaskFilterType {
  all,
  completed,
  incomplete,
  withFiles,
  withoutFiles,
  withDeadline,
  withoutDeadline;

  String label(AppLocalizations l10n) {
    switch (this) {
      case TaskFilterType.all:
        return l10n.filterAll;
      case TaskFilterType.completed:
        return l10n.filterCompleted;
      case TaskFilterType.incomplete:
        return l10n.filterIncomplete;
      case TaskFilterType.withFiles:
        return l10n.filterWithFiles;
      case TaskFilterType.withoutFiles:
        return l10n.filterWithoutFiles;
      case TaskFilterType.withDeadline:
        return l10n.filterWithDeadline;
      case TaskFilterType.withoutDeadline:
        return l10n.filterWithoutDeadline;
    }
  }
}
