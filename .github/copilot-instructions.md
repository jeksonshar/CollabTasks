# CollabTasks — AI Agent Guidelines & Architecture Laws

## 1. Architectural Core (Laws)

- **Clean Architecture:** Strict separation into three layers:
    - `domain/`: Pure business models (`copyWith`, `toMap`), UseCases, and Repository Interfaces. NO framework, NO database, NO storage details.
    - `data/`: Repository implementations, DataSources (Drift/SQLite), network, and mapping.
    - `ui/`: Presentation layer (Screens, Widgets, Dialogs, Blocs/Cubits).
- **Dependency Injection:** Use `GetIt` as a service locator (`lib/di/service_locator.dart`). All Repositories, UseCases, and Blocs must be registered
  in `setupLocator()`.
- **State Management:** Strict `flutter_bloc` pattern (`BlocListener`, `BlocBuilder`). Riverpod is in dependencies but NOT used. Never use it.
- **UI Constraints:** NO business rules, NO validation, NO text formatting inside UI widgets. UI only reflects the state.
- **Data Flow:** Unidirectional only: UI → Bloc/Cubit → UseCase → Repository → DataSource.

## 2. Context Scope & Token Efficiency

- **Priority Scope:** Always prioritize analyzing and editing files inside `lib/`, `test/`, `pubspec.yaml`, `analysis_options.yaml`, and `docs/`.
- **Ignore List:** Ignore `android/`, `ios/`, `web/`, `macos/`, `linux/`, `windows/` unless explicitly requested.
- **No Generated Noise:** Never read, analyze, or suggest edits in generated files (`*.g.dart`, `*.freezed.dart`, `app_localizations*.dart`).
- **Summarization Rule:** For large updates or new modules, output a high-level structural overview (architecture plan) *before* writing any Dart
  code.

## 3. Layer & Component Rules

### Domain Layer

- **Models:** Immutable classes in `domain/models/` with `copyWith()`, `toMap()`, `fromMap()`.
- **Use Cases:** Thin wrappers around repositories (e.g., `GetTasksUseCase`). Named as `[Action][Target]UseCase`. File names must be snaked_case
  matching the class.
- **Error Handling:** No Result/Either wrapper pattern; propagate exceptions directly to Blocs. Use enum-based error typing (`TaskErrorType`) with
  stack-trace logging.

### Data Layer (Persistence & Serialization)

- **ORM:** Drift ORM with SQLite. Entities live in `data/local/db/entities/`. Migrations are in `AppDatabase` (increment `schemaVersion` on changes).
- **Upsert Pattern:** Always use Drift `insertOnConflictUpdate` for save/update operations (see `TaskRepositoryImpl._upsertTask`).
- **Serialization:** JSON via `toMap()`/`fromMap()`. Attachments must be encoded as JSON strings.

### UI Layer (Presentation)

- **Structure:** Screens in `ui/screens/` (StatefulWidget allowed for internal UI state), dialogs in `ui/dialogs/`, blocs in `ui/blocs/`.
- **Bloc Interactions:** Separate files for `_event.dart`, `_state.dart`, and `_bloc.dart` per feature. Always use immutable updates (emit new state
  copies).
- **Side Effects:** Use `MultiBlocListener` and `BlocListener` for errors, navigation, and dialogs. Use `BlocBuilder` strictly for rendering.

## 4. Project-Specific Tech Stack Patterns

- **Rich Text:** Use `flutter_quill`. Store content strictly as JSON Delta strings (see `Task.text`, `TaskDialog`).
- **Attachments:** Use `file_picker` + `open_filex`. Store as `TaskAttachment` list containing local paths.
- **Sorting:** Perform a client-side task sorting directly in Bloc logic (by date/priority/title with direction toggle).
- **Dialog State:** `TaskDialog` must own its `QuillController` and internal form state.
- **Priority:** Use custom `TaskPriority` and utility classes from `core/task_priority/`.

## 5. Critical Workflows & CLI Commands

- **Code Gen:** Run `flutter pub run build_runner build` after Drift entity or table changes.
- **Localization:** Use `L10nMixin` / `AppLocalizations` accessors. Run `flutter gen-l10n` after updating ARB files in `lib/l10n/`.
- **Dependencies:** Run `flutter pub get` after `pubspec.yaml` modifications.

## 6. Documentation Sync

- Every feature change or architectural shift must be updated in `docs/`.
- For new features, strictly follow the template in `docs/features/template.md`. Use only technical descriptions and Mermaid diagrams. No marketing
  fluff.

## 7. Testing Patterns

- **Bloc Tests:** Use the `blocTest` package. Seed the state, verify transitions, and test event listeners.
- **Widget Tests:** Always reset and reinitialize DI before each test execution.
```dart
SharedPreferences.setMockInitialValues(Map<String, Object>());
getIt.reset();
setupLocator();
```
