import 'package:collab_tasks/features/settings/domain/repositories/app_settings_repository.dart';

class SetSavedLanguageUseCase {
  final AppSettingsRepository repository;

  SetSavedLanguageUseCase(this.repository);

  Future<void> call(String languageCode) => repository.setLanguageCode(languageCode);
}
