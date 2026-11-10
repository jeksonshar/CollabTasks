# Plan: Android Groups Widget

- **ID:** 0004
- **Status:** Complete
- **Created:** 2026-11-10
- **Goal:** Add a dark, scrollable 3×3 Android home-screen widget for working groups, participants, and group tasks
  while preserving the existing personal task widget.

## Scope

- Display the current working groups in a vertically scrollable Android home-screen widget.
- Expand and collapse each group to show participants followed by group tasks, each with a heading.
- Open a participant's direct chat, a group task details screen, or the working groups screen from the corresponding
  widget tap.
- Keep the groups snapshot synchronized with the app's group and group-detail streams.
- Register a separate Android widget provider and MethodChannel so personal-task widget navigation and updates remain
  independent.
- Use the existing app models, streams, direct-chat use case, and task-details screen; do not change Drift schema or add
  dependencies.

## Files in scope

| File                                                                             | Intended change                                                                                                                           |
|:---------------------------------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------|
| `android/app/src/main/AndroidManifest.xml`                                       | Register a distinct GroupsWidget receiver and metadata resource.                                                                          |
| `android/app/src/main/kotlin/com/example/collab_tasks/MainActivity.kt`           | Add a separate groups-widget MethodChannel and route its initial and warm-start navigation requests without changing task-widget routing. |
| `android/app/src/main/kotlin/com/example/collab_tasks/GroupsHomeGlanceWidget.kt` | Add the dark, scrollable Glance widget, cached snapshot, per-group expand/collapse state, and tap actions.                                |
| `android/app/src/main/res/xml/groups_home_widget_info.xml`                       | Define the new provider's 3×3 default size and resize behavior.                                                                           |
| `android/app/src/main/res/values/task_widget_strings.xml`                        | Add the GroupsWidget description string.                                                                                                  |
| `lib/features/working_groups/data/widgets/groups_widget_bridge.dart`             | Serialize group, participant, and task summaries and handle the separate native channel.                                                  |
| `lib/features/working_groups/ui/widgets/groups_widget_bloc_listener.dart`        | Watch group and group-detail streams, refresh the native snapshot, and route widget taps to app screens.                                  |
| `lib/features/tasks/ui/screens/main_screen/main_screen.dart`                     | Mount the groups-widget listener alongside the existing personal-task widget listener.                                                    |
| `docs/features/android_groups_widget.md`                                         | Document architecture, synchronization, tap behavior, and manual verification scenarios using the feature template.                       |
| `docs/features/android_task_widget.md`                                           | Document coexistence with GroupsWidget and preservation of personal-task widget flows.                                                    |
| `docs/plans/0004-android-groups-widget.md`                                       | Track scope, approved steps, acceptance checks, and progress.                                                                             |
| `docs/memory/handoff.md`                                                         | Point to the active plan and record the recovery checkpoint.                                                                              |

## Steps

- [x] Implement the Android provider, widget UI, description resource, and separate navigation channel. Files:
  `AndroidManifest.xml`, `MainActivity.kt`, `GroupsHomeGlanceWidget.kt`, `groups_home_widget_info.xml`, and
  `task_widget_strings.xml` (paths as listed above). `:app:compileDebugKotlin` passed.
- [x] Implement Flutter snapshot synchronization and navigation, and update both widget feature documents. Files:
  `groups_widget_bridge.dart`, `groups_widget_bloc_listener.dart`, `main_screen.dart`, `android_groups_widget.md`, and
  `android_task_widget.md` (paths as listed above). Updated the approved native participant action to pass
  `GroupParticipant.id` so the existing direct-chat use case receives its expected composite ID. Updated handoff as part
  of the approved step.
- [x] Run focused checks and review the diff. `:app:compileDebugKotlin`, focused Dart analysis, and `git diff --check`
  passed. No tests were added or run. Record launcher-only scenarios as unverified and return handoff to idle.

## Acceptance checks

- [ ] Android registers both widgets independently, each with a 3×3 default size; the personal task widget remains
  installable and functional.
- [ ] GroupsWidget renders a dark, vertically scrollable list with group rows; tapping a group expands/collapses
  participants and tasks under their respective headings.
- [ ] Group, participant, and task rows use compact styling consistent with the corresponding in-app components.
- [ ] Adding/removing a group while the app is active updates the widget snapshot; refreshed participant/task streams
  update expanded content.
- [ ] A participant tap opens that participant's direct chat; a task tap opens its group task details screen; tapping
  widget background opens the working groups screen.
- [ ] The personal task widget's snapshot, refresh, task navigation, and background navigation flows are unchanged.
- [x] Focused platform and Flutter checks succeed; device/launcher interaction is recorded as not checked.

## Testing matrix

| Component                                              | Layer                 | Test file(s)                                                                                                              | Behaviors and cases covered                                                                          |
|:-------------------------------------------------------|:----------------------|:--------------------------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------|
| Groups widget bridge and native Glance provider        | Data / Platform       | No automated test planned in this change; record focused compilation and manual launcher scenarios.                       | Snapshot refresh, separate provider/channel, expanded/collapsed groups, and item/background actions. |
| Flutter widget synchronization and navigation listener | UI / Integration      | No automated test planned in this change; verify through focused static checks and manual app navigation where available. | Added/removed groups, detail updates, direct chat, group task details, and groups screen routing.    |
| Existing personal task widget                          | Platform / Regression | Existing coverage and manual scenario; no new test file planned.                                                          | Confirm personal task rendering and task/background actions remain available alongside GroupsWidget. |

## Recovery checkpoint

- **Last completed step:** Implemented the native GroupsWidget and Flutter stream/navigation bridge, updated both
  feature documents, and passed Kotlin compilation, focused Dart analysis, and `git diff --check`.
- **Next action:** None. Device-level installation and launcher interaction remain unverified.
- **Changed or uncommitted files:** All files listed in this plan; none staged or committed.
- **Known failures or blockers:** Device-level launcher rendering and taps were not checked. Gradle emitted existing
  Kotlin plugin compatibility warnings; compilation succeeded.
