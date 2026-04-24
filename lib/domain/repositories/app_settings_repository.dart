import '../models/task_view_preferences.dart';

abstract class AppSettingsRepository {
  Future<String?> getLanguageCode();

  Future<void> setLanguageCode(String languageCode);

  Future<TaskViewPreferences> getTaskViewPreferences();

  Future<void> setTaskViewPreferences(TaskViewPreferences preferences);
}
