# CollabTasks - AI Agent Guidelines

## Context Scope (Token Efficiency)

- **Default analysis scope**: prioritize `lib/`, `test/`, `pubspec.yaml`, `analysis_options.yaml`, and relevant `docs/`.
- **Ignore by default**: `android/`, `ios/`, `web/`, `macos/`, `linux/`, `windows/` unless explicitly requested.
- **Generated files**: do not analyze or edit generated artifacts unless explicitly requested (`*.g.dart`, `*.freezed.dart`, generated l10n files like `app_localizations*.dart`).

## Architecture Overview

- **Clean Architecture**: strict separation into `domain/` (business logic), `data/` (implementations), `ui/` (presentation).
- **Dependency Injection**: GetIt service locator (`di/service_locator.dart`). Register all repositories, use cases, and blocs in `setupLocator()`.
- **State Management**: `flutter_bloc` (`TaskBloc`, `LocaleCubit`). Riverpod is listed in dependencies but **not currently used**.
- **Data Flow**: UI → BlocListener/BlocBuilder → Bloc/Cubit → UseCase → Repository → DataSource (unidirectional).
- **App Initialization**: In `main()`, initialize `SharedPreferences`, call `setupLocator()`, initialize `NotificationsManager`, then create `MultiBlocProvider` in root widget.

## Layer Rules

- **UI layer**: no business rules, validation, or data formatting that belongs to domain/application logic.
- **Domain layer**: pure business models/use-cases/contracts, no framework or storage details.
- **Data layer**: repository/data source implementations, mapping between persistence and domain models.

## Key Components

- **Domain Models**: immutable classes in `domain/models/` with `copyWith()`, `toMap()`, `fromMap()` (e.g., `Task`).
- **Use Cases**: thin wrappers around repository calls (e.g., `GetTasksUseCase`). No Result wrapper pattern; exceptions propagate directly.
- **Repository Pattern**: interfaces in `domain/repositories/`, implementations in `data/repositories/`.
- **Persistence**: Drift ORM with SQLite, entities in `data/local/db/entities/`, migrations in `AppDatabase`.
- **UI Structure**: screens in `ui/screens/` (often StatefulWidget for managing UI state), dialogs in `ui/dialogs/`, blocs in `ui/blocs/`.
- **Bloc Listeners**: use `MultiBlocListener` and `BlocListener` for side effects (errors, navigation, dialogs). Use `BlocBuilder` for state rendering.

## Testing Patterns

- **Widget Tests**: Reset `getIt` before each test, set mock `SharedPreferences`, manually call `setupLocator()`, use `tester.pumpWidget()` with initialized blocs.
- **Bloc Tests**: Use `blocTest` package. Seed state, verify state transitions, test event listeners.
- **Setup Example**: `SharedPreferences.setMockInitialValues({})` → `getIt.reset()` → `setupLocator()` → test.

## Critical Workflows

- **Code Generation**: run `flutter pub run build_runner build` after Drift entity/table changes.
- **Localization**: run `flutter gen-l10n` after updating ARB files in `lib/l10n/`.
- **Dependencies**: run `flutter pub get` after dependency changes.
- **Database Migrations**: increment `schemaVersion` in `AppDatabase` and add migration logic.

## Project-Specific Patterns

- **Rich Text**: use `flutter_quill`, store as JSON Delta strings (see `Task.text`, `TaskDialog`).
- **Attachments**: use `file_picker` + `open_filex`, store as `TaskAttachment` list with local paths.
- **Sorting**: client-side task sorting in bloc logic by date/priority/title with direction toggle.
- **Errors**: enum-based error typing (`TaskErrorType`) with stack-trace logging.
- **Dialog State**: `TaskDialog` owns `QuillController` and internal form state.
- **Priority System**: custom `TaskPriority` + utils in `core/task_priority/`.

## Conventions

- **Serialization**: JSON via `toMap()`/`fromMap()`, attachments encoded as JSON strings.
- **Upsert**: use Drift `insertOnConflictUpdate` for add/update (`TaskRepositoryImpl._upsertTask`).
- **Localization Access**: use `L10nMixin` / `AppLocalizations` accessors. Run `flutter gen-l10n` after ARB file changes.
- **Immutable Updates**: always create new lists/objects when updating bloc state.
- **Use Case Naming**: `[Action][Target]UseCase` (e.g., `GetTasksUseCase`, `AddTaskUseCase`). File names match class name in snake_case.
- **Bloc/Cubit File Organization**: separate files for events (`task_event.dart`), state (`task_state.dart`), and bloc (`task_bloc.dart`) in a feature folder.

## Documentation Sync

- Keep architecture and feature docs in sync with actual code changes.
- For new feature docs, use `docs/features/template.md`.
