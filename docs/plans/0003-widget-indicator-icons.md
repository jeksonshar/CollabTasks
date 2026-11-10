# Plan: Android Widget Indicator Icons

- **ID:** 0003
- **Status:** Complete
- **Created:** 2026-11-10
- **Goal:** Replace the Unicode symbols used for task metadata in the Android home-screen widget with vector icons
  matching the Flutter task list indicators.

## Scope

- Render checklist, alarm, and attachment icons for subtasks, deadlines, and attachments.
- Preserve the associated values, conditional visibility, spacing, deadline color, and dark widget styling.
- Do not change task data, the widget refresh flow, or task-list behavior.

## Files in scope

| File                                                                           | Intended change                                                                                        |
|:-------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------------|
| `android/app/src/main/kotlin/com/example/collab_tasks/TaskHomeGlanceWidget.kt` | Replace symbol-prefixed indicator strings with Glance image and text elements using the new drawables. |
| `android/app/src/main/res/drawable/ic_widget_checklist.xml`                    | Add a vector drawable for the subtasks checklist indicator.                                            |
| `android/app/src/main/res/drawable/ic_widget_alarm.xml`                        | Add a vector drawable for the deadline indicator.                                                      |
| `android/app/src/main/res/drawable/ic_widget_attach_file.xml`                  | Add a vector drawable for the attachment indicator.                                                    |
| `docs/features/android_task_widget.md`                                         | Document the icon mapping and add the device-level indicator rendering scenario to the test matrix.    |
| `docs/plans/0003-widget-indicator-icons.md`                                    | Track this plan, approvals, implementation, and checks.                                                |
| `docs/memory/handoff.md`                                                       | Point to the active plan and record the recovery checkpoint.                                           |

## Steps

- [x] Implement the three drawable indicators and update Glance rendering; update the feature document in the same
  approved step.
- [x] Run `:app:compileDebugKotlin` and review the diff. Device-level rendering was not checked.
- [x] Mark the plan complete and return the handoff to idle.

## Acceptance checks

- [x] Subtasks render the checklist icon with completed/total count.
- [x] Deadlines render the alarm icon with the date and preserve overdue coloring.
- [x] Attachments render the attach_file icon with the attachment count.
- [x] Conditional visibility, indicator spacing, and dark styling remain intact.
- [x] `:app:compileDebugKotlin` succeeds.
- [x] The feature document records a manual device scenario for tasks with each indicator; Android launcher rendering
  remains unchecked because no device or emulator was used.

## Recovery checkpoint

- **Last completed step:** Implemented and documented the widget metadata indicators; Kotlin compilation succeeded.
- **Next action:** None.
- **Changed or uncommitted files:** See this plan's scope; none were staged or committed.
- **Known failures or blockers:** Device-level launcher rendering was not checked.
