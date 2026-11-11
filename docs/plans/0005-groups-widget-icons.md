# Plan: Groups Widget Material Icons

- **ID:** 0005
- **Status:** Complete
- **Created:** 2026-11-11
- **Goal:** Replace text glyphs in the Android GroupsWidget with Material-style vector icons while preserving its Glance
  implementation.

## Scope

- Replace the group, expand/collapse, chevron, and task-status text glyphs with Glance images backed by Android vector
  drawables.
- Reuse the existing task status drawables and add vector resources for the missing icons.
- Keep the widget's colors, tap actions, state, and layout behavior unchanged apart from icon rendering.
- Document the icon resources and their rendering check in the GroupsWidget feature document.
- Do not add a Compose Material Icons dependency. Glance uses its own composables and supports drawable resources
  through `ImageProvider`.

## Files in scope

| File                                                                             | Intended change                                                                                                                              |
|:---------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------|
| `android/app/src/main/kotlin/com/example/collab_tasks/GroupsHomeGlanceWidget.kt` | Replace Unicode group, expand/collapse, chevron, and task status symbols with tinted Glance `Image` components backed by drawable resources. |
| `android/app/src/main/res/drawable/ic_widget_groups.xml`                         | Add a Material-style groups vector drawable.                                                                                                 |
| `android/app/src/main/res/drawable/ic_widget_keyboard_arrow_up.xml`              | Add a Material-style expand/collapse up-arrow vector drawable.                                                                               |
| `android/app/src/main/res/drawable/ic_widget_keyboard_arrow_down.xml`            | Add a Material-style expand/collapse down-arrow vector drawable.                                                                             |
| `android/app/src/main/res/drawable/ic_widget_chevron_right.xml`                  | Add a Material-style right-chevron vector drawable.                                                                                          |
| `docs/features/android_groups_widget.md`                                         | Document the icon resources and update the manual rendering verification scenario.                                                           |
| `docs/plans/0005-groups-widget-icons.md`                                         | Track the approved scope, implementation step, acceptance checks, and verification.                                                          |
| `docs/memory/handoff.md`                                                         | Point to this active plan and record the current checkpoint.                                                                                 |

Existing `ic_widget_task_alt.xml` and `ic_widget_circle_outlined.xml` are reused unchanged.

## Steps

- [x] Implement and document the approved icon replacements. Update the plan and handoff in the same step.
- [x] Review the diff and run the approved focused Android Kotlin compilation plus `git diff --check`; no tests were
  run. Launcher rendering remains unverified.

## Acceptance checks

- [ ] Group header uses the groups icon; expanded and collapsed states use keyboard arrow up/down icons.
- [ ] Participant and group-task rows use the right-chevron icon.
- [ ] Completed and incomplete group tasks use the task-alt and circle-outlined vector icons, tinted with the existing
  priority color.
- [ ] Group/task taps, expansion state, dark styling, and personal task widget remain unchanged.
- [x] Focused Kotlin compilation succeeds and the diff passes whitespace checks; launcher rendering is recorded
  accurately.

## Testing matrix

| Component                    | Layer    | Test file(s)                                                                                             | Behaviors and cases covered                                                                                              |
|:-----------------------------|:---------|:---------------------------------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------|
| Groups Glance icon rendering | Platform | No automated widget test planned; use focused Kotlin compilation and launcher inspection when available. | Group icon, expanded/collapsed arrows, row chevrons, completed/incomplete task icons, tint, and preserved group actions. |

## Recovery checkpoint

- **Last completed step:** Replaced the icon glyphs with drawable-backed Glance images, added four vector assets,
  updated the GroupsWidget feature document, and passed focused Kotlin compilation plus `git diff --check`.
- **Next action:** None. Verify visual rendering on a launcher when convenient.
- **Changed or uncommitted files:** All files listed in this plan; none staged or committed.
- **Known failures or blockers:** Launcher rendering was not checked. Gradle emitted existing Kotlin plugin
  compatibility and deprecation warnings; compilation succeeded.
