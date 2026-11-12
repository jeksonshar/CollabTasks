# Plan: Immediate Android Widget Locale Refresh

- **ID:** 0009
- **Status:** Complete; device verification pending
- **Created:** 2026-11-12
- **Goal:** Re-render both installed Glance widgets immediately when the app locale changes, without requiring
  interaction with a widget.

## Diagnosis

- The selected locale is persisted in native `SharedPreferences`, but each Glance composition currently reads it outside
  of Glance state.
- The locale update requests a widget refresh while the Glance preference state may remain unchanged. A later user
  action changes Glance state and causes the new localized context to become visible, matching the reported delayed
  behavior.

## Scope

- Store the selected locale in each installed widget instance's Glance `Preferences` state alongside its current data
  snapshot.
- Read the locale from Glance state during composition and use it to construct the localized resource context.
- Explicitly update each installed task and groups widget instance after writing the locale state.
- Complete the locale MethodChannel request after both widget providers have finished scheduling their instance updates.
- Preserve existing widget snapshots, navigation, and locale fallback behavior.
- Document the immediate-refresh behavior and its verification status.

## Files in scope

| File                                                                             | Intended change                                                                                                 |
|:---------------------------------------------------------------------------------|:----------------------------------------------------------------------------------------------------------------|
| `android/app/src/main/kotlin/com/example/collab_tasks/MainActivity.kt`           | Persist the locale and await both widget-cache locale-update operations before returning success to Flutter.    |
| `android/app/src/main/kotlin/com/example/collab_tasks/TaskHomeGlanceWidget.kt`   | Add locale to task widget Glance state and explicitly update each task widget instance when locale changes.     |
| `android/app/src/main/kotlin/com/example/collab_tasks/GroupsHomeGlanceWidget.kt` | Add locale to groups widget Glance state and explicitly update each groups widget instance when locale changes. |
| `docs/features/android_task_widget.md`                                           | Document that locale updates trigger an immediate per-instance Glance refresh.                                  |
| `docs/features/android_groups_widget.md`                                         | Document that locale updates trigger an immediate per-instance Glance refresh.                                  |
| `docs/plans/0009-android-widget-locale-refresh.md`                               | Track approved scope, implementation, checks, and recovery state.                                               |
| `docs/memory/handoff.md`                                                         | Point to plan 0009 and record the recovery checkpoint.                                                          |

## Steps

- [x] Add per-instance Glance locale state and explicitly refresh both widget providers. Update docs, plan, and handoff
  in the same step.
- [x] Review the state-update path, run Android Kotlin/resource compilation and `git diff --check`; do not run
  application tests unless requested. Record device interaction as unverified unless checked on-device.

## Acceptance checks

- [x] Changing app locale writes Glance state for installed personal-task and groups widgets and explicitly requests
  per-instance updates without widget interaction.
- [x] Each active Glance instance receives the selected `en`, `ru`, or `uk` locale in its own state and renders from
  that locale.
- [x] Newly installed widget instances fall back to the saved native locale before their first app-data refresh.
- [x] Task/group snapshots and existing navigation behavior remain unchanged by the focused code changes.
- [x] Android Kotlin/resource compilation and whitespace checks succeed; actual launcher behavior is reported
  accurately.
- [ ] On-device confirmation: switch app language and observe both installed widgets update without tapping them.

## Testing matrix

| Component                    | Layer    | Test file(s)                                                                            | Behaviors and cases covered                                                                                     |
|:-----------------------------|:---------|:----------------------------------------------------------------------------------------|:----------------------------------------------------------------------------------------------------------------|
| Native locale update handler | Platform | No direct automated test planned; verify with Kotlin compilation and launcher scenario. | Persists locale, updates both providers, and responds after both update operations are scheduled.               |
| Personal task Glance state   | Platform | No direct automated widget test planned; verify with launcher scenario.                 | Locale state changes trigger immediate composition; task snapshot and refresh action keep working.              |
| Groups Glance state          | Platform | No direct automated widget test planned; verify with launcher scenario.                 | Locale state changes trigger immediate composition; group snapshot, expand action, and navigation keep working. |

## Recovery checkpoint

- **Last completed step:** Implemented and reviewed per-instance locale state, explicit widget updates, and the awaited
  native channel response. `:app:compileDebugKotlin` and `git diff --check` succeeded.
- **Next action:** Verify the visible locale refresh on an Android launcher when available.
- **Changed or uncommitted files:** Files listed in the approved scope; no commit was made.
- **Known failures or blockers:** Device reproduction and launcher verification remain pending.
