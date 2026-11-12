# Plan: Android Widget Localization

- **ID:** 0008
- **Status:** Complete; device verification pending
- **Created:** 2026-11-12
- **Goal:** Localize both Android home-screen widgets in English, Russian, and Ukrainian, using the language selected in
  the app for live Glance widget content.

## Scope

- Synchronize the resolved Flutter app locale with the Android widget layer and refresh both Glance widgets when it
  changes.
- Move fixed labels, empty-state text, accessibility descriptions, participant/task section labels, and plural counts
  out of Kotlin literals into Android string/plural resources for `en`, `ru`, and `uk`.
- Localize sample text in both picker preview layouts and widget descriptions using Android resource qualifiers.
- Provide localized fallback PNG previews for English, Russian, and Ukrainian.
- Keep user-provided group, participant, and task names unchanged.
- Picker `previewLayout` and `previewImage` are static Android resources selected using the Android resource/device
  locale. They cannot directly observe the Flutter-only language preference. Live installed Glance widgets will follow
  the app-selected locale through the locale bridge.
- Do not modify the unregistered legacy `TaskHomeWidgetProvider` RemoteViews implementation or its layouts; the manifest
  registers the Glance receiver instead.
- Do not change widget navigation, data snapshots, or widget appearance beyond translated text.

## Files in scope

| File                                                                             | Intended change                                                                                                       |
|:---------------------------------------------------------------------------------|:----------------------------------------------------------------------------------------------------------------------|
| `android/app/src/main/kotlin/com/example/collab_tasks/MainActivity.kt`           | Accept the app-selected widget locale, persist it natively, and refresh both Glance providers.                        |
| `android/app/src/main/kotlin/com/example/collab_tasks/GroupsHomeGlanceWidget.kt` | Resolve localized group labels, plurals, and accessibility descriptions using the saved app locale.                   |
| `android/app/src/main/kotlin/com/example/collab_tasks/TaskHomeGlanceWidget.kt`   | Resolve localized task labels, empty state, metadata text, and accessibility descriptions using the saved app locale. |
| `lib/features/tasks/ui/screens/main_screen/main_screen.dart`                     | Send the resolved locale to the Android widget bridge when the app locale changes.                                    |
| `lib/features/tasks/data/widgets/task_widget_bridge.dart`                        | Add the Android-only locale synchronization call.                                                                     |
| `android/app/src/main/res/values/task_widget_strings.xml`                        | Define English widget and picker-preview strings and plurals as the default resources.                                |
| `android/app/src/main/res/values-ru/task_widget_strings.xml`                     | Add Russian widget and picker-preview strings and plurals.                                                            |
| `android/app/src/main/res/values-uk/task_widget_strings.xml`                     | Add Ukrainian widget and picker-preview strings and plurals.                                                          |
| `android/app/src/main/res/layout/task_home_widget_preview.xml`                   | Replace hard-coded preview text with localized string/plural references.                                              |
| `android/app/src/main/res/layout/groups_home_widget_preview.xml`                 | Replace hard-coded preview text with localized string/plural references.                                              |
| `android/app/src/main/res/drawable-nodpi/task_widget_preview.png`                | Replace the Russian static fallback with an English preview, used as the default fallback.                            |
| `android/app/src/main/res/drawable-nodpi/groups_widget_preview.png`              | Replace the Russian static fallback with an English preview, used as the default fallback.                            |
| `android/app/src/main/res/drawable-ru-nodpi/task_widget_preview.png`             | Add the Russian personal-task fallback preview.                                                                       |
| `android/app/src/main/res/drawable-ru-nodpi/groups_widget_preview.png`           | Add the Russian groups fallback preview.                                                                              |
| `android/app/src/main/res/drawable-uk-nodpi/task_widget_preview.png`             | Add the Ukrainian personal-task fallback preview.                                                                     |
| `android/app/src/main/res/drawable-uk-nodpi/groups_widget_preview.png`           | Add the Ukrainian groups fallback preview.                                                                            |
| `docs/features/android_task_widget.md`                                           | Document live-widget locale synchronization and picker-preview locale behavior.                                       |
| `docs/features/android_groups_widget.md`                                         | Document live-widget locale synchronization and picker-preview locale behavior.                                       |
| `docs/plans/0008-android-widget-localization.md`                                 | Track approved scope, implementation, checks, and recovery state.                                                     |
| `docs/memory/handoff.md`                                                         | Point to plan 0008 and record the recovery checkpoint.                                                                |

## Steps

- [x] Implement locale synchronization, Android translations, localized picker resources, and feature documentation.
  Update the plan and handoff in the same step.
- [x] Review translation/resource coverage and run Android resource processing plus `git diff --check`. Do not run
  application tests unless requested. Report device behavior as unverified unless checked on-device.

## Acceptance checks

- [x] Changing language in Settings to `en`, `ru`, or `uk` sends the new locale to Android and requests an update of
  both Glance providers without restarting the app.
- [x] On app startup, both widgets receive the resolved app locale, including the selected saved locale.
- [x] All fixed visible and accessibility text in the active Kotlin widget composables is translated; user-provided
  task/group/participant text remains unchanged.
- [x] Android string/plural resources provide complete `en`, `ru`, and `uk` values; resource-name parity was checked
  across all three sets.
- [x] Both XML picker previews and their metadata descriptions use localized Android resources.
- [x] Fallback PNG previews exist for English, Russian, and Ukrainian, with English as the unqualified fallback; all six
  images were visually inspected.
- [x] Preview locale follows Android resource/device locale; app-specific Flutter locale synchronization applies to live
  Glance widgets.
- [x] Android Kotlin/resource compilation and `git diff --check` succeeded; widget navigation and data flow are
  unchanged.

## Testing matrix

| Component                               | Layer                | Test file(s)                                                                                           | Behaviors and cases covered                                                                                                  |
|:----------------------------------------|:---------------------|:-------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------|
| Flutter-to-native locale bridge         | UI / Platform        | No direct automated test planned; verify resource processing and manual language switching.            | Sends `en`, `ru`, and `uk`; handles Android-only bridge and refreshes both widget providers.                                 |
| Task Glance widget localization         | Platform             | No direct automated widget test planned; verify Kotlin/resource compilation and launcher scenarios.    | Header, empty state, refresh/status accessibility labels, metadata labels, and translated date formatting follow app locale. |
| Groups Glance widget localization       | Platform             | No direct automated widget test planned; verify Kotlin/resource compilation and launcher scenarios.    | Empty state, section headers/plurals, group expansion and task-status accessibility labels follow app locale.                |
| Picker previews and widget descriptions | Platform / Resources | No automated test planned; inspect preview resources and verify on an Android launcher when available. | XML strings/plurals and static fallback images resolve for `en`, `ru`, and `uk` according to Android resource locale.        |

## Recovery checkpoint

- **Last completed step:** Implemented and reviewed the approved localization scope; resource parity matched across all
  locales, Android compilation succeeded, and `git diff --check` passed.
- **Next action:** Verify switching languages and refreshed widgets on an Android device when available.
- **Changed or uncommitted files:** Files listed in the approved scope; no commit was made.
- **Known failures or blockers:** Device interaction was not tested. Picker preview resources follow Android
  resource/device locale and cannot read the app's Flutter-only locale preference directly. Flutter's debug build also
  reports two untranslated Ukrainian messages elsewhere in the app.
