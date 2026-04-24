import '../repositories/app_settings_repository.dart';

class GetSavedLanguageUseCase {
  final AppSettingsRepository repository;

  GetSavedLanguageUseCase(this.repository);

  Future<String?> call() => repository.getLanguageCode();
}
