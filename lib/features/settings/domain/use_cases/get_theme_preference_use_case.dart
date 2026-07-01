import 'package:collab_tasks/features/settings/domain/models/theme_preference.dart';
import 'package:collab_tasks/features/settings/domain/repositories/app_settings_repository.dart';

class GetThemePreferenceUseCase {
  final AppSettingsRepository _repository;

  GetThemePreferenceUseCase(this._repository);

  Future<ThemePreference> call() => _repository.getThemePreference();
}
