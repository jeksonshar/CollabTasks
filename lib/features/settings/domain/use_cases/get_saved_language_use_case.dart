import 'package:collab_tasks/features/settings/domain/repositories/app_settings_repository.dart';

class GetSavedLanguageUseCase {
  final AppSettingsRepository repository;

  GetSavedLanguageUseCase(this.repository);

  Future<String?> call() => repository.getLanguageCode();
}
