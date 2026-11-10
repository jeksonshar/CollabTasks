# Feature: AndroidTaskWidget

## 1. Business Goal & Value

- **Purpose:** Display a dark, vertically scrollable list of personal tasks in an Android home-screen widget.
- **User Stories Covered:** Tap a task to open personal tasks with that task expanded; tap the widget background to open
  personal tasks with every task collapsed; tap the refresh action to redraw the widget from its latest saved task snapshot
  without opening the app.
- The widget UI is authored in Kotlin with Jetpack Glance; Android's required widget metadata XML only registers the
  widget and provides its initial loading layout.
- The same scrollable home-screen widget is not available on iOS because iOS widgets do not support user-controlled
  scrolling.

## 2. Architectural Blueprint (Clean Architecture)

### Domain Layer

- **Models:** Existing `Task` domain model.
- **Use Cases:** Existing task use cases; no new business operation.
- **Repository Interface:** Existing task repository.

### Data Layer

- **Local Persistence (Drift):** No database or schema change. Android stores a minimal widget snapshot (ID, title,
  priority, completion state, pin state, subtask progress, deadline, and attachment count) in app-private
  SharedPreferences and mirrors it into per-widget Glance state so active widget compositions observe changes.
- **Data Mappers:** Flutter maps domain tasks to the widget payload in `TaskWidgetBridge`.
- **Remote Data:** None.

### Presentation Layer (UI & Bloc)

- **Bloc / Cubit:** Existing `TaskBloc`; task taps dispatch `NotificationTaskOpened`, background taps dispatch
  `WidgetHomeOpened` to clear the highlighted task and reset filters. Refresh is handled natively by a Glance
  `ActionCallback`, which reloads the saved snapshot into Glance state and redraws the widget without starting
  `MainActivity`.
- **Components & Screens:** `TaskWidgetBlocListener` synchronizes task state and receives tap events; Android
  `GlanceAppWidget` renders the dark Compose list. `HomeTasksScreen` uses highlighted-task state to expand the selected
  task or collapse all tasks.

## 3. Testing Matrix

| Component                                    | Layer           | Test file(s) | Behaviors and cases covered                                                                                                            |
|:---------------------------------------------|:----------------|:-------------|:---------------------------------------------------------------------------------------------------------------------------------------|
| Task widget bridge and Android Glance widget | Data / Platform | N/A | No direct tests added; launcher hit targets, icon rendering, and cache refresh need device or emulator integration coverage. |
| Widget task navigation and refresh | Bloc / UI | N/A | Task taps reuse highlighted-task state; background taps clear the highlight. No direct automated coverage added. |

- **Domain:** N/A; no domain behavior changed.
- **Data:** Android mirrors the presentation snapshot into per-widget Glance state; Drift remains the application task
  persistence.
- **Persistence and migrations:** N/A; Drift schema is unchanged.
- **Bloc/Cubit:** Widget task taps reuse `NotificationTaskOpened`; `WidgetHomeOpened` clears highlighted state and
  resets the filter/search. Widget refresh redraws from the cached task snapshot and does not start a repository sync.
- **Widgets and screens:** Existing highlighted-task expansion flow is reused.
- **Integration or regression:** Device-level launcher integration remains to be exercised.

## 4. Data Flow & State Machine (Mermaid)

```mermaid
graph TD
    DB[(Task data)] --> Bloc[TaskBloc]
    Bloc --> Listener[TaskWidgetBlocListener]
    Listener -->|minimal JSON snapshot| Channel[Android MethodChannel]
    Channel --> Cache[(Android widget cache)]
    Cache -->|snapshot per widget ID| State[(Glance DataStore state)]
    State --> Provider[GlanceAppWidget and currentState]
    Provider --> List[Dark scrollable Glance list]
    List -->|task ID or background tap| Activity[MainActivity]
    Activity -->|openTask or openHome| Listener
    Listener -->|NotificationTaskOpened or WidgetHomeOpened| Bloc
    Bloc --> Screen[HomeTasksScreen]
    Screen --> Expanded[Selected task expanded]
    List -->|refresh tap| Callback[Glance ActionCallback]
    Callback -->|updateAll| Provider
```
