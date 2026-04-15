# CollabTasks - AI Agent Guidelines

## Architecture Overview

- **Clean Architecture**: Strict separation into `domain/` (business logic), `data/` (implementations), `ui/` (presentation)
- **Dependency Injection**: GetIt for service locator pattern (see `di/service_locator.dart`)
- **State Management**: Provider with ChangeNotifier ViewModels (e.g., `TaskViewModel`)
- **Data Flow**: UI → ViewModel → UseCase → Repository → DataSource (unidirectional)

## Key Components

- **Domain Models**: Immutable classes in `domain/models/` with `copyWith()`, `toMap()`, `fromMap()` (e.g., `Task`)
- **Use Cases**: Thin wrappers around repository calls (e.g., `GetTasksUseCase`)
- **Repository Pattern**: Abstract interfaces in `domain/repositories/`, implementations in `data/repositories/`
- **Persistence**: Drift ORM with SQLite, entities in `data/local/db/entities/`, migrations in `AppDatabase`
- **UI Structure**: Screens in `ui/screens/`, dialogs in `ui/dialogs/`, ViewModels in `ui/view_models/`

## Critical Workflows

- **Code Generation**: Run `flutter pub run build_runner build` after modifying Drift entities or adding new tables
- **Localization**: Run `flutter gen-l10n` after updating ARB files in `lib/l10n/`
- **Dependencies**: `flutter pub get` to install packages
- **Database Migrations**: Increment `schemaVersion` in `AppDatabase` and add migration logic for schema changes

## Project-Specific Patterns

- **Rich Text Handling**: Use `flutter_quill` for text editing, store as JSON Delta strings (see `Task.text`, `TaskDialog`)
- **File Attachments**: Use `file_picker` for selection, `open_filex` for opening; store as `TaskAttachment` list with local paths
- **Task Sorting**: Client-side sorting in `TaskViewModel._sortTasks()` by date/priority/title with direction toggle
- **Error Handling**: Enum-based error types in ViewModels (e.g., `TaskErrorType`), logged with stack traces
- **Dialog State**: `TaskDialog` owns `QuillController` and manages form state internally
- **Priority System**: Custom `TaskPriority` enum with utils in `core/task_priority/`

## Conventions

- **Model Serialization**: JSON via `toMap()`/`fromMap()`, attachments encoded as JSON strings
- **Database Upsert**: Use Drift's `insertOnConflictUpdate` for add/update operations (see `TaskRepositoryImpl._upsertTask`)
- **Localization Keys**: Access via `L10nMixin` in widgets (e.g., `localization.addTaskTitle`)
- **Immutable Updates**: Always create new lists/objects for state changes, notify listeners

## Example Patterns

- **Adding a Feature**: Create domain model → repository interface → use case → data impl → ViewModel method → UI widget
- **Database Query**: Use Drift DAOs with type-safe queries, map to domain models in repository
- **UI Updates**: Call `notifyListeners()` in ViewModel after state changes, use `Consumer` or `context.watch` in widgets
