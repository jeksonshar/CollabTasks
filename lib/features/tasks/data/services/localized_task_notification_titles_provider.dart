import 'dart:ui';

import 'package:collab_tasks/features/settings/domain/repositories/app_settings_repository.dart';
import 'package:collab_tasks/features/tasks/domain/services/task_notification_titles_provider.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:collab_tasks/l10n/app_localizations_en.dart';
import 'package:collab_tasks/l10n/app_localizations_ru.dart';
import 'package:collab_tasks/l10n/app_localizations_uk.dart';

class LocalizedTaskNotificationTitlesProvider implements TaskNotificationTitlesProvider {
  LocalizedTaskNotificationTitlesProvider(this._settingsRepository);

  final AppSettingsRepository _settingsRepository;

  @override
  Future<TaskNotificationTitles> getTitles() async {
    final savedLanguageCode = await _settingsRepository.getLanguageCode();
    final localizations = _localizationsFor(
      savedLanguageCode ?? PlatformDispatcher.instance.locale.languageCode,
    );

    return TaskNotificationTitles(
      reminderTitle: localizations.deadlineIn30MinutesTitle,
      deadlineTitle: localizations.deadlineReachedTitle,
    );
  }

  AppLocalizations _localizationsFor(String languageCode) {
    switch (languageCode) {
      case 'ru':
        return AppLocalizationsRu();
      case 'uk':
        return AppLocalizationsUk();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }
}
