# CollabTasks — AI Agent Guidelines & Architecture Laws

## 1. Architectural Core (Laws)

- **Clean Architecture:** Strict separation into three layers:
    - `domain/`: Pure business models (`copyWith`, `toMap`), UseCases, and Repository Interfaces. NO framework, NO
      database, NO storage details.
    - `data/`: Repository implementations, DataSources (Drift/SQLite), network, and mapping.
    - `ui/`: Presentation layer (Screens, Widgets, Dialogs, Blocs/Cubits).
- **Dependency Injection:** Use `GetIt` as a service locator (`lib/di/service_locator.dart`). All Repositories,
  UseCases, and Blocs must be registered
  in `setupLocator()`.
- **State Management:** Strict `flutter_bloc` pattern (`BlocListener`, `BlocBuilder`). Riverpod is in dependencies but
  NOT used. Never use it.
- **UI Constraints:** NO business rules, NO validation, NO text formatting inside UI widgets. UI only reflects the
  state.
- **Adaptive UI:** Every UI feature or bug fix must preserve its critical user flow across the available app window
  sizes and supported orientations. For Android, use the current official Android Adaptive App Quality Tier 3 checklist
  as the baseline for affected flows. Do not treat Tier 3 as a requirement for a specific visual layout; the required
  outcome is that the app remains functional, full-window, and state-preserving.
- **Data Flow:** Unidirectional only: UI → Bloc/Cubit → UseCase → Repository → DataSource.

## 2. Context Scope & Token Efficiency

- **Priority Scope:** Always prioritize analyzing and editing files inside `lib/`, `test/`, `pubspec.yaml`,
  `analysis_options.yaml`, and `docs/`.
- **Ignore List:** Ignore `android/`, `ios/`, `web/`, `macos/`, `linux/`, `windows/` unless explicitly requested.
- **Adaptive Platform Scope:** For an explicitly requested adaptive UI task, inspect Android/iOS configuration only when
  needed to verify orientation, resizability, multi-window, or supported device behavior. Keep platform changes narrowly
  scoped and explain why each change is needed. Do not modify other platform folders unless explicitly requested.
- **No Generated Files:** Never read, analyze, edit, or suggest edits to generated files (`*.g.dart`, `*.freezed.dart`,
  `app_localizations*.dart`).
- **Summarization Rule:** For large updates or new modules, output a high-level structural overview (architecture plan)
  *before* writing any Dart
  code.

## 3. Layer & Component Rules

### Domain Layer

- **Models:** Immutable classes in `domain/models/` with `copyWith()`, `toMap()`, `fromMap()`.
- **Use Cases:** Thin wrappers around repositories (e.g., `GetTasksUseCase`). Named as `[Action][Target]UseCase`. File
  names must be snaked_case
  matching the class.
- **Error Handling:** No Result/Either wrapper pattern; propagate exceptions directly to Blocs. Use enum-based error
  typing (`TaskErrorType`) with
  stack-trace logging.

### Data Layer (Persistence & Serialization)

- **ORM:** Drift ORM with SQLite. Entities live in `data/local/db/entities/`. Migrations are in `AppDatabase` (increment
  `schemaVersion` on changes).
- **Upsert Pattern:** Always use Drift `insertOnConflictUpdate` for save/update operations (see
  `TaskRepositoryImpl._upsertTask`).
- **Serialization:** JSON via `toMap()`/`fromMap()`. Attachments must be encoded as JSON strings.

### UI Layer (Presentation)

- **Structure:** Screens in `ui/screens/` (StatefulWidget allowed for internal UI state), dialogs in `ui/dialogs/`,
  blocs in `ui/blocs/`.
- **Bloc Interactions:** Separate files for `_event.dart`, `_state.dart`, and `_bloc.dart` per feature. Always use
  immutable updates (emit new state
  copies).
- **State and Controller Lifecycle:** Keep shared and business state in Bloc/Cubit and short-lived presentation state in
  the owning `StatefulWidget`, consistent with the existing feature pattern. Create and dispose controllers with their
  owning widget state; do not recreate controllers during ordinary rebuilds. Keep Bloc providers above responsive
  branches when the Bloc must survive layout changes. Do not add or move providers solely to enforce a blanket rule
  against `BlocProvider` or `getIt` usage in `build()`.
- **Side Effects:** Use `MultiBlocListener` and `BlocListener` for errors, navigation, and dialogs. Use `BlocBuilder`
  strictly for rendering.
- **Theme and Localization:** Use the existing theme and `Theme.of(context)` for colors and text styles. Use
  `AppLocalizations` or `L10nMixin` for user-facing strings; do not introduce hard-coded localized text or colors where
  project theme values exist.

### Adaptive UI

- **Window-Based Layout:** Choose layouts from the available window constraints, not from device model names. Use
  `LayoutBuilder`, `MediaQuery` window metrics, or an existing shared responsive utility as appropriate.
- **Breakpoint Policy:** Do not hard-code different breakpoints in individual screens. Select shared breakpoint values
  during the responsive architecture plan, centralize them in a shared UI utility, and document their rationale.
- **No Fixed-Screen Assumptions:** Do not assume a fixed screen width, height, or aspect ratio. Keep content within the
  available window, including when the keyboard is open or the app is in split-screen or a resizable window.
- **Insets and Foldables:** Respect system insets and avoid placing critical controls or content under reported display
  features such as a hinge or fold. Do not add model-specific or tri-fold-specific behavior unless the platform exposes
  a relevant feature and the product requires it.
- **State Continuity:** When layout changes due to rotation, folding/unfolding, window resizing, or navigation between
  compact and wide layouts, preserve relevant user state: text input, scroll position, selected item, active task/chat,
  and ongoing media or call state.
- **Multi-Window:** Do not introduce orientation or resize restrictions that prevent the app from filling the available
  app window. Ensure affected flows remain usable when another app has focus.
- **Multi-Resume:** In multi-window mode, keep relevant live UI data updated while the app is not the top-focused
  window. Handle loss and restoration of exclusive resources such as the camera and microphone.
- **Orientation and Resizability:** Do not lock orientation or set Android `resizeableActivity="false"` for the app
  unless a platform requirement makes it necessary. Document any exception and verify that the app still meets the
  current Android adaptive app quality requirements.
- **Full-Window Rendering:** The app must use the available screen or app-window area without app-imposed letterboxing
  or compatibility mode. Content must not overflow or become inaccessible when the app window changes size.
- **External Input:** All visible controls and text fields in affected flows must work with a physical keyboard and
  basic mouse/trackpad input. Basic stylus interaction should continue to work through standard Flutter controls.
- **Keyboard Switching:** For affected text-entry flows, verify that connecting or disconnecting a physical keyboard
  switches between hardware and software keyboard input without restarting the app, while preserving entered text and
  focus.
- **Conditional Media Requirements:** If a change touches camera preview or screen/media projection, verify orientation,
  proportions, folding/unfolding, and window resizing. If an app flow uses the microphone or camera, handle resource
  loss and regain when window focus changes.
- **Responsive Scope:** Tier 3 requires functional, full-window behavior. Multi-pane layouts and form-factor-specific
  enhancements are improvements beyond the Tier 3 baseline; do not add them unless they fit the feature or the approved
  implementation plan.
- **UI Layer Boundary:** Responsive layout code belongs in UI. Do not move business rules, validation, or data
  formatting into widgets to implement adaptive behavior.

## 4. Project-Specific Tech Stack Patterns

- **Rich Text:** Use `flutter_quill`. Store content strictly as JSON Delta strings (see `Task.text`, `TaskDialog`).
- **Attachments:** Use `file_picker` + `open_filex`. Store as `TaskAttachment` list containing local paths.
- **Sorting:** Perform a client-side task sorting directly in Bloc logic (by date/priority/title with direction toggle).
- **Dialog State:** `TaskDialog` must own its `QuillController` and internal form state.
- **Priority:** Use custom `TaskPriority` and utility classes from `core/task_priority/`.

## 5. Critical Workflows & CLI Commands

- **Code Gen:** Run `flutter pub run build_runner build` after Drift entity or table changes.
- **Localization:** Use `L10nMixin` / `AppLocalizations` accessors. Run `flutter gen-l10n` after updating ARB files in
  `lib/l10n/`.
- **Dependencies:** Run `flutter pub get` after `pubspec.yaml` modifications.
- **Google Play Adaptive Requirements:** Before an Android release or store submission, check the current official
  adaptive app quality and target API requirements. Do not rely on dates or target API levels copied into this file.

## 6. Documentation Sync

- Every feature change or architectural shift must be updated in `docs/`.
- For new features, strictly follow the template in `docs/features/template.md`. Use only technical descriptions and
  Mermaid diagrams. No marketing
  fluff.
- **Adaptive UI Changes:** When changing responsive breakpoints, navigation behavior, multi-window behavior, or state
  continuity, update the relevant technical documentation and record which form factors and states were verified. Do not
  describe an untested device or configuration as verified.

## 7. Testing Patterns

- **Bloc Tests:** Use the `blocTest` package. Seed the state, verify transitions, and test event listeners.
- **Widget Tests:** Always reset and reinitialize DI before each test execution.
- **Adaptive UI Verification:** For each UI change, identify the affected screens and verify the relevant states:
  compact and wide windows, portrait and landscape, keyboard open, and resizable or split-screen mode where applicable.
- **Continuity Checks:** For affected flows with text input, scrollable content, ongoing media, or calls, verify that
  the relevant state is retained across rotation, folding/unfolding, and window resizing.
- **External Input Checks:** For affected flows, verify text entry with a physical keyboard and basic
  control/selection/scrolling with a mouse or trackpad. Verify stylus text input when the flow and test device support
  it.
- **Conditional Camera/Projection Checks:** When touching camera preview or media projection, verify orientation and
  proportions in supported orientations and resizable windows. When touching calls, verify camera/microphone behavior
  when app focus changes.
- **Verification Reporting:** Report which checks were actually run and on what device or emulator. Mark unavailable
  checks as “not verified”; never infer device verification from code inspection alone.

```dart
SharedPreferences.setMockInitialValues(Map<String, Object>());
getIt.reset();
setupLocator();
```
