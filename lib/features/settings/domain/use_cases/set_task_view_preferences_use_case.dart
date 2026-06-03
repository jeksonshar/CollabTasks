import 'package:collab_tasks/features/settings/domain/models/task_view_preferences.dart';
import 'package:collab_tasks/features/settings/domain/repositories/app_settings_repository.dart';

class SetTaskViewPreferencesUseCase {
  final AppSettingsRepository repository;

  SetTaskViewPreferencesUseCase(this.repository);

  Future<void> call(TaskViewPreferences preferences) {
    return repository.setTaskViewPreferences(preferences);
  }
}
