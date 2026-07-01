import 'package:collab_tasks/features/settings/domain/models/task_view_preferences.dart';
import 'package:collab_tasks/features/settings/domain/models/theme_preference.dart';

abstract class AppSettingsRepository {
  Future<String?> getLanguageCode();

  Future<void> setLanguageCode(String languageCode);

  Future<TaskViewPreferences> getTaskViewPreferences();

  Future<void> setTaskViewPreferences(TaskViewPreferences preferences);

  Future<ThemePreference> getThemePreference();

  Future<void> setThemePreference(ThemePreference preference);
}
