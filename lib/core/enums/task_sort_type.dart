import '../../l10n/app_localizations.dart';

enum TaskSortType { byDateCreated, byPriority, byTitle }

extension TaskSortTypeX on TaskSortType {
  String label(AppLocalizations localization) {
    return switch (this) {
      TaskSortType.byDateCreated => localization.sortByDate,
      TaskSortType.byPriority => localization.sortByPriority,
      TaskSortType.byTitle => localization.sortByTitle,
    };
  }
}
