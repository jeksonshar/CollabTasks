import 'package:collab_tasks/features/settings/domain/models/task_view_preferences.dart';
import 'package:collab_tasks/features/settings/domain/repositories/app_settings_repository.dart';

class GetTaskViewPreferencesUseCase {
  final AppSettingsRepository repository;

  GetTaskViewPreferencesUseCase(this.repository);

  Future<TaskViewPreferences> call() => repository.getTaskViewPreferences();
}
