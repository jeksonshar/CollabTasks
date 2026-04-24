import '../../domain/models/task_view_preferences.dart';
import '../../domain/repositories/app_settings_repository.dart';
import '../datastore/app_settings_datastore.dart';

class AppSettingsRepositoryImpl implements AppSettingsRepository {
  final AppSettingsDatastore _datastore;

  AppSettingsRepositoryImpl(this._datastore);

  @override
  Future<String?> getLanguageCode() async => _datastore.getLanguageCode();

  @override
  Future<void> setLanguageCode(String languageCode) {
    return _datastore.setLanguageCode(languageCode);
  }

  @override
  Future<TaskViewPreferences> getTaskViewPreferences() async {
    final sortType = _datastore.getTaskSortType();
    final sortDirection = _datastore.getTaskSortDirection();
    final filterType = _datastore.getTaskFilterType();
    const defaultPreferences = TaskViewPreferences();

    return TaskViewPreferences(
      sortType: sortType ?? defaultPreferences.sortType,
      sortDirection: sortDirection ?? defaultPreferences.sortDirection,
      filterType: filterType ?? defaultPreferences.filterType,
    );
  }

  @override
  Future<void> setTaskViewPreferences(TaskViewPreferences preferences) async {
    await _datastore.setTaskSortType(preferences.sortType);
    await _datastore.setTaskSortDirection(preferences.sortDirection);
    await _datastore.setTaskFilterType(preferences.filterType);
  }
}
