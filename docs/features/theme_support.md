# Поддержка Light и Dark тем (Theme Support)

## Описание

Реализована полная поддержка переключения между Light и Dark темами оформления приложения с возможностью:

- Выбора светлой, темной или системной темы
- Сохранения выбора пользователя локально
- Немедленного применения выбранной темы при переключении

## Архитектура

### Domain Layer

- **Модель**: `ThemePreference` (`lib/features/settings/domain/models/theme_preference.dart`)
    - Enum: `AppThemeMode { light, dark, system }`
    - Immutable класс с поддержкой `Equatable` для правильного сравнения
    - Методы сериализации: `toMap()`, `fromMap()`

- **UseCase**:
    - `GetThemePreferenceUseCase` — получение сохраненной темы
    - `SetThemePreferenceUseCase` — сохранение выбранной темы

### Data Layer

- **AppSettingsDatastore** — работа с `SharedPreferences`
    - Ключ: `theme_mode`
    - Методы: `getThemeMode()`, `setThemeMode()`

- **AppSettingsRepository** — реализует интерфейс для работы с темой

### UI Layer (Presentation)

- **ThemeBloc** (`lib/features/settings/ui/blocs/theme_bloc/`)
    - Разделен на три файла:
        - `theme_event.dart` — события (`ThemeInitialized`, `ThemeModeChanged`)
        - `theme_state.dart` — состояние (`isLoading`, `themePreference`)
        - `theme_bloc.dart` — бизнес-логика

    - Функциональность:
        - Загрузка сохраненной темы при инициализации
        - Изменение темы с сохранением
        - Обработка ошибок с логированием
        - Состояние загрузки для UI feedback

### Core Theme

- **AppTheme** (`lib/core/theme/app_theme.dart`)
    - `lightTheme()` — Light тема с Material 3
    - `darkTheme()` — Dark тема с Material 3
    - Кастомизация:
        - AppBar (фон, стили текста)
        - Card (фон, elevation)
        - Input fields (цвета заливки и текста)
        - ListTile (цвета иконок и текста)

## Интеграция

### Main App (`lib/main.dart`)

```dart
BlocBuilder<LocaleCubit, Locale?>
(
builder: (context, locale) {
return BlocBuilder<ThemeBloc, ThemeState>(
builder: (context, themeState) {
final themeModeValue = _mapThemeModeToFlutterThemeMode(
themeState.themePreference.mode
);
return MaterialApp(
themeMode: themeModeValue,
theme: AppTheme.lightTheme(),
darkTheme: AppTheme.darkTheme(),
...
);
},
);
},
);
```

### Settings Screen (`lib/features/settings/ui/screens/settings_screen/`)

- Dropdown для выбора темы (Light / Dark / System)
- Интеграция с `ThemeBloc` для изменения темы
- Использование `AppLocalizations` для локализованных строк

## Локализация

Добавлены строки в ARB файлы:

- `settingsTheme` — "Theme" / "Тема оформления" / "Тема оформлення"
- `settingsThemeLight` — "Light" / "Светлая" / "Світла"
- `settingsThemeDark` — "Dark" / "Тёмная" / "Темна"
- `settingsThemeSystem` — "System" / "Системная" / "Системна"

## DI (Dependency Injection)

Регистрация в `lib/di/service_locator.dart`:

```dart
getIt..registerLazySingleton
(
() => GetThemePreferenceUseCase(getIt()))
..registerLazySingleton(() => SetThemePreferenceUseCase(getIt()))
..registerFactory(() => ThemeBloc(
getThemePreferenceUseCase: getIt(),
setThemePreferenceUseCase: getIt()
,
)
)
```

## Тесты

- **Файл**: `test/features/settings/ui/blocs/theme_bloc_test.dart`
- **Покрытие**:
    - ✅ Инициализация с системной темой по умолчанию
    - ✅ Загрузка сохраненной темы успешно
    - ✅ Переключение на светлую тему
    - ✅ Переключение на темную тему
    - ✅ Переключение на системную тему
    - ✅ Обработка ошибок при загрузке
    - ✅ Обработка ошибок при изменении

## Файлы, созданные/изменены

### Созданные файлы:

1. `lib/core/theme/app_theme.dart` — ThemeData для light/dark
2. `lib/features/settings/domain/models/theme_preference.dart` — модель
3. `lib/features/settings/domain/use_cases/get_theme_preference_use_case.dart`
4. `lib/features/settings/domain/use_cases/set_theme_preference_use_case.dart`
5. `lib/features/settings/ui/blocs/theme_bloc/theme_event.dart`
6. `lib/features/settings/ui/blocs/theme_bloc/theme_state.dart`
7. `lib/features/settings/ui/blocs/theme_bloc/theme_bloc.dart`
8. `test/features/settings/ui/blocs/theme_bloc_test.dart`

### Изменённые файлы:

1. `lib/main.dart` — добавлен BlocBuilder для ThemeBloc
2. `lib/di/service_locator.dart` — регистрация UseCases и Bloc
3. `lib/features/settings/data/datastore/app_settings_datastore.dart` — методы для темы
4. `lib/features/settings/domain/repositories/app_settings_repository.dart` — контракт
5. `lib/features/settings/data/repositories/app_settings_repository_impl.dart` — имплементация
6. `lib/features/settings/ui/screens/settings_screen/settings_screen.dart` — UI для выбора
7. `lib/l10n/app_en.arb` — английские строки
8. `lib/l10n/app_ru.arb` — русские строки
9. `lib/l10n/app_uk.arb` — украинские строки

## Паттерны соответствия проекту

✅ **Clean Architecture** — строгое разделение на Domain, Data, UI
✅ **flutter_bloc** — использован BlocBuilder, никакого Riverpod
✅ **Immutable state** — все состояния неизменяемы с copyWith()
✅ **GetIt DI** — все зависимости зарегистрированы
✅ **L10nMixin/AppLocalizations** — все строки локализованы
✅ **SharedPreferences** — сохранение в AppSettingsDatastore
✅ **Equatable** — правильное сравнение для тестов
✅ **Unit Tests** — полное покрытие Bloc функциональности

## Использование

1. Пользователь открывает Settings
2. Выбирает тему из Dropdown (Light / Dark / System)
3. Выбор сразу сохраняется в SharedPreferences
4. Тема немедленно применяется через MaterialApp.themeMode
5. При перезагрузке приложения тема восстанавливается
