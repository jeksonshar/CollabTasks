# Plan: Android Widget Bridge Tests

- **ID:** 0010
- **Status:** Complete
- **Created:** 2026-11-12
- **Goal:** Add focused Flutter tests for the task and groups widget bridge contracts.

## Scope

- Test the personal-task bridge's Android method-channel contract: compact snapshot serialization, empty task snapshots,
  initial navigation, locale synchronization for supported languages, unsupported locale rejection, and non-Android
  no-op behavior.
- Test the groups bridge's method-channel contract: group/participant/task snapshot serialization, invited/accepted
  participant deduplication with accepted-record preference, current-user identity, assignee-name mapping, empty group
  snapshots, and navigation payload parsing.
- Update both widget feature test matrices to identify these test files and distinguish bridge coverage from Android
  Glance rendering/launcher verification.
- Keep tests hermetic with Flutter's test binary messenger; do not add dependencies.
- Do not modify production widget code or add Android instrumentation/Robolectric configuration. The repository
  currently has no Android widget test harness; Glance rendering, per-instance locale refresh, launcher registration,
  and real widget interactions remain platform/device verification scenarios.

## Files in scope

| File                                                                       | Intended change                                                                                                                                          |
|:---------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------|
| `test/features/tasks/data/widgets/task_widget_bridge_test.dart`            | Add channel contract tests for task snapshots, empty data, initial navigation, locale updates, and platform guards.                                      |
| `test/features/working_groups/data/widgets/groups_widget_bridge_test.dart` | Add channel contract tests for group snapshots, participant deduplication/current-user mapping, task assignee names, empty data, and navigation parsing. |
| `docs/features/android_task_widget.md`                                     | Map the bridge test file to covered cases and retain native rendering/launcher checks as manual.                                                         |
| `docs/features/android_groups_widget.md`                                   | Map the bridge test file to covered cases and retain native rendering/launcher checks as manual.                                                         |
| `docs/plans/0010-android-widget-tests.md`                                  | Track approved scope, implementation, checks, and recovery state.                                                                                        |
| `docs/memory/handoff.md`                                                   | Point to plan 0010 and record the recovery checkpoint.                                                                                                   |

## Steps

- [x] Add both bridge test suites and update feature test matrices. Update plan and handoff in the same step.
- [x] Run the two focused Flutter test files and `git diff --check`; do not run the full application suite unless
  requested. Record native Glance/device coverage as unverified.

## Acceptance checks

- [x] Task bridge tests verify the serialized keys/values and omission of full task content, empty snapshots, initial
  navigation parsing, and locale calls for `en`, `ru`, and `uk`.
- [x] Task bridge tests verify unsupported locales and non-Android targets do not send native method calls.
- [x] Groups bridge tests verify encoded group data, invitation deduplication with accepted participant preference,
  current-user flags, assignee-name resolution, empty snapshots, and initial navigation parsing.
- [x] Both feature documents map tested behavior to the new files and clearly state that Flutter bridge tests do not
  exercise the Android Glance renderer or launcher.
- [x] Both focused test files and whitespace checks pass; no dependencies are added.

## Testing matrix

| Component                                         | Layer                    | Test file(s)                                                                                             | Behaviors and cases covered                                                                                                               |
|:--------------------------------------------------|:-------------------------|:---------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------|
| Task widget bridge                                | Data / Platform contract | `test/features/tasks/data/widgets/task_widget_bridge_test.dart`                                          | Snapshot serialization, empty snapshot, native initial navigation, locale codes, unsupported locale, and platform guard.                  |
| Groups widget bridge                              | Data / Platform contract | `test/features/working_groups/data/widgets/groups_widget_bridge_test.dart`                               | Group payload serialization, participant deduplication/current-user mapping, assigned-user names, empty snapshot, and navigation parsing. |
| Android Glance providers and launcher integration | Platform                 | No Android widget test harness configured; verify with Kotlin compilation and device launcher scenarios. | Rendered appearance, collection scrolling, per-instance immediate locale refresh, widget registration, and user interactions.             |

## Recovery checkpoint

- **Last completed step:** Both focused Flutter test files passed (12 tests total); `git diff --check` passed; no
  dependencies or production files changed.
- **Next action:** None. Android Glance rendering and launcher scenarios remain device-level checks outside this plan.
- **Changed or uncommitted files:** Both widget bridge test files, both widget feature documents, this plan, and
  `docs/memory/handoff.md`.
- **Known failures or blockers:** None. Android Glance UI behavior remains outside the current Flutter test harness and
  was not verified here.
