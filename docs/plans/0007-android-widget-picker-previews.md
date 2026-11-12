# Plan: Android Widget Picker Previews

- **ID:** 0007
- **Status:** Complete
- **Created:** 2026-11-12
- **Goal:** Replace the generic Android widget-picker placeholders with rounded dark previews for personal tasks and
  groups.

## Scope

- Add scalable `previewLayout` resources for both widgets, containing static sample rows styled to match the supplied
  references.
- Add `previewImage` PNG fallbacks for widget hosts that do not use the preview layout, including Android 11 and lower
  and Android 15+ before a generated preview is registered.
- Use generic demo content only; do not include live task or participant data from the supplied screenshots.
- Apply rounded dark outer corners and rounded inner cards in both scalable and bitmap previews.
- Keep runtime Glance widget layouts, update behavior, navigation, and personal/groups widget coexistence unchanged.
- Update both widget feature documents. Do not add dependencies or modify app runtime code.

## Files in scope

| File                                                                | Intended change                                                                                                    |
|:--------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------|
| `android/app/src/main/res/xml/task_home_widget_info.xml`            | Register personal-task `previewLayout` and `previewImage` resources.                                               |
| `android/app/src/main/res/xml/groups_home_widget_info.xml`          | Register GroupsWidget `previewLayout` and `previewImage` resources.                                                |
| `android/app/src/main/res/layout/task_home_widget_preview.xml`      | Add a rounded dark scalable preview with a title/count/refresh row and sample task cards and indicators.           |
| `android/app/src/main/res/layout/groups_home_widget_preview.xml`    | Add a rounded dark scalable preview with sample collapsed and expanded group cards, participant, and task content. |
| `android/app/src/main/res/drawable/widget_preview_background.xml`   | Add the rounded dark outer preview background.                                                                     |
| `android/app/src/main/res/drawable/widget_preview_card.xml`         | Add the rounded inner card background.                                                                             |
| `android/app/src/main/res/drawable-nodpi/task_widget_preview.png`   | Add a static fallback preview for the personal task widget, using generic sample data.                             |
| `android/app/src/main/res/drawable-nodpi/groups_widget_preview.png` | Add a static fallback preview for GroupsWidget, using generic sample data.                                         |
| `docs/features/android_task_widget.md`                              | Document the picker preview resources and fallback behavior.                                                       |
| `docs/features/android_groups_widget.md`                            | Document the picker preview resources and fallback behavior.                                                       |
| `docs/plans/0007-android-widget-picker-previews.md`                 | Track approved scope, implementation, acceptance checks, and verification.                                         |
| `docs/memory/handoff.md`                                            | Point to the active plan and record the recovery checkpoint.                                                       |

## Steps

- [x] Implement the preview layouts, fallback images, metadata, and documentation. Update the plan and handoff in the
  same step.
- [x] Review the rendered preview images and diff; run Android resource processing and `git diff --check`. Do not run
  application tests unless requested. Record device-picker behavior as unverified unless checked on-device.

## Acceptance checks

- [x] Personal task preview resembles the supplied dark task-widget reference, with a title/count/refresh header and
  multiple rounded task rows.
- [x] Groups preview resembles the supplied dark groups reference, with a count, rounded group cards, expand controls,
  and expanded participant/task examples.
- [x] The preview silhouette has rounded corners; inner cards also have rounded corners.
- [x] Both widget providers refer to the corresponding preview layout and static image fallback.
- [x] Preview samples contain no live user data; runtime widget layouts and actions are unchanged.
- [x] Android resource processing and whitespace checks succeed; device-picker behavior is reported accurately.

## Testing matrix

| Component                    | Layer                 | Test file(s)                                                                                                           | Behaviors and cases covered                                                                                                 |
|:-----------------------------|:----------------------|:-----------------------------------------------------------------------------------------------------------------------|:----------------------------------------------------------------------------------------------------------------------------|
| Personal task picker preview | Platform / Resources  | No automated test planned; verify by resource processing, rendered-image inspection, and device picker when available. | Correct sample task styling, metadata mapping, dark rounded background, and fallback image.                                 |
| Groups picker preview        | Platform / Resources  | No automated test planned; verify by resource processing, rendered-image inspection, and device picker when available. | Collapsed/expanded group examples, participant/task styling, metadata mapping, dark rounded background, and fallback image. |
| Runtime widget behavior      | Platform / Regression | No runtime source changes; verify existing Glance behavior remains unchanged in focused review.                        | Both installed widgets retain their existing rendering, state, and navigation after preview metadata changes.               |

## Recovery checkpoint

- **Last completed step:** Added both widget picker layouts and static fallback images, registered them in provider
  metadata, documented the previews, and reviewed the PNGs.
- **Next action:** None; implementation and resource checks are complete. Verify the actual picker on a device or
  launcher when available.
- **Changed or uncommitted files:** The Android preview resource files and both feature documents listed in the scope
  above, plus this plan and `docs/memory/handoff.md`.
- **Known failures or blockers:** Device-picker behavior was not checked on a physical device; static PNG and XML
  previews were visually inspected locally.
