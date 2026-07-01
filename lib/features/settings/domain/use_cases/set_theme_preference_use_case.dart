import 'package:collab_tasks/features/settings/domain/models/theme_preference.dart';
import 'package:collab_tasks/features/settings/domain/repositories/app_settings_repository.dart';

class SetThemePreferenceUseCase {
  final AppSettingsRepository _repository;

  SetThemePreferenceUseCase(this._repository);

  Future<void> call(ThemePreference preference) => _repository.setThemePreference(preference);
}
