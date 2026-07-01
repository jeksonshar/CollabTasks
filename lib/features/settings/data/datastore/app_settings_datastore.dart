import 'package:collab_tasks/core/enums/task_filter_type.dart';
import 'package:collab_tasks/core/enums/task_sort_direction.dart';
import 'package:collab_tasks/core/enums/task_sort_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsDatastore {
  static const _languageCodeKey = 'locale_language_code';
  static const _taskSortTypeKey = 'task_sort_type';
  static const _taskSortDirectionKey = 'task_sort_direction';
  static const _taskFilterTypeKey = 'task_filter_type';
  static const _themeModeKey = 'theme_mode';

  final SharedPreferences _preferences;

  AppSettingsDatastore(this._preferences);

  String? getLanguageCode() => _preferences.getString(_languageCodeKey);

  Future<void> setLanguageCode(String languageCode) async {
    await _preferences.setString(_languageCodeKey, languageCode);
  }

  TaskSortType? getTaskSortType() => _readEnum(key: _taskSortTypeKey, values: TaskSortType.values);

  Future<void> setTaskSortType(TaskSortType value) async {
    await _preferences.setString(_taskSortTypeKey, value.name);
  }

  TaskSortDirection? getTaskSortDirection() =>
      _readEnum(key: _taskSortDirectionKey, values: TaskSortDirection.values);

  Future<void> setTaskSortDirection(TaskSortDirection value) async {
    await _preferences.setString(_taskSortDirectionKey, value.name);
  }

  TaskFilterType? getTaskFilterType() =>
      _readEnum(key: _taskFilterTypeKey, values: TaskFilterType.values);

  Future<void> setTaskFilterType(TaskFilterType value) async {
    await _preferences.setString(_taskFilterTypeKey, value.name);
  }

  String? getThemeMode() => _preferences.getString(_themeModeKey);

  Future<void> setThemeMode(String themeMode) async {
    await _preferences.setString(_themeModeKey, themeMode);
  }

  T? _readEnum<T extends Enum>({required String key, required List<T> values}) {
    final raw = _preferences.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    for (final value in values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }
}
