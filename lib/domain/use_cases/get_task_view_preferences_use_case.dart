import '../models/task_view_preferences.dart';
import '../repositories/app_settings_repository.dart';

class GetTaskViewPreferencesUseCase {
  final AppSettingsRepository repository;

  GetTaskViewPreferencesUseCase(this.repository);

  Future<TaskViewPreferences> call() => repository.getTaskViewPreferences();
}
