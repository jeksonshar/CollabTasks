import '../models/task_view_preferences.dart';
import '../repositories/app_settings_repository.dart';

class SetTaskViewPreferencesUseCase {
  final AppSettingsRepository repository;

  SetTaskViewPreferencesUseCase(this.repository);

  Future<void> call(TaskViewPreferences preferences) {
    return repository.setTaskViewPreferences(preferences);
  }
}
