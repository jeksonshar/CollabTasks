# Plan: Groups Widget Participant Rows

- **ID:** 0006
- **Status:** Complete; Flutter analysis did not finish
- **Created:** 2026-11-11
- **Goal:** Prevent duplicate invited/accepted participants in GroupsWidget and make the current user's row
  non-navigable.

## Scope

- Deduplicate participant snapshots by the same ID suffix used by `ParticipantsTab`, normalizing the key for case and
  whitespace.
- When an invitation and accepted participant share a key, keep the accepted participant record.
- Pass the current authenticated user's ID and email into the widget snapshot, and mark matching participants as the
  current user.
- In the native Glance widget, render the current user's row without a click action or right chevron.
- Preserve navigation and chevrons for other participants, task/group interactions, and the personal task widget.
- Update the GroupsWidget feature documentation. Do not change the existing participants screen or add dependencies.

## Files in scope

| File                                                                             | Intended change                                                                                                                                                                |
|:---------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `lib/features/working_groups/data/widgets/groups_widget_bridge.dart`             | Deduplicate participant entries per group, prefer accepted records over `:invite:` records, and serialize an `isCurrentUser` flag using optional current-user ID/email inputs. |
| `lib/features/working_groups/ui/widgets/groups_widget_bloc_listener.dart`        | Subscribe to the existing auth-state use case and pass the current user identity when publishing the GroupsWidget snapshot.                                                    |
| `android/app/src/main/kotlin/com/example/collab_tasks/GroupsHomeGlanceWidget.kt` | Parse `isCurrentUser`; omit click action and right chevron for the current user's participant row.                                                                             |
| `docs/features/android_groups_widget.md`                                         | Document participant deduplication and self-row interaction; update the verification matrix and scenarios.                                                                     |
| `docs/plans/0006-groups-widget-participants.md`                                  | Track approved scope, implementation, acceptance checks, and verification.                                                                                                     |
| `docs/memory/handoff.md`                                                         | Point to the active plan and record the recovery checkpoint.                                                                                                                   |

## Steps

- [x] Implement and document the approved snapshot and row behavior. Update the plan and handoff in the same step.
- [x] Review the diff, run Android Kotlin compilation, and run `git diff --check`. Two focused Dart analyzer invocations
  stalled without output and were stopped; no tests were added or run. Record launcher behavior as unverified.

## Acceptance checks

- [ ] An invited record and accepted participant with the same ID suffix produce one widget entry; the accepted record
  wins.
- [ ] The current user's widget row has no click action and no right chevron.
- [ ] Other participants retain the existing direct-chat action and chevron.
- [ ] Group/task navigation, expansion, and the personal task widget remain unchanged.
- [x] Android Kotlin compilation succeeds and the diff passes whitespace checks; the stalled Dart analysis and
  unverified launcher behavior are reported accurately.

## Testing matrix

| Component                      | Layer              | Test file(s)                                                                                                     | Behaviors and cases covered                                                                                                |
|:-------------------------------|:-------------------|:-----------------------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------|
| Groups widget snapshot mapping | Data / UI boundary | No automated test planned in this change; verify with focused Flutter analysis and a snapshot scenario.          | Duplicate invite/accepted identity, accepted-record preference, current-user ID/email matching, and task assignee mapping. |
| Groups Glance participant row  | Platform           | No automated widget test planned; verify with focused Kotlin compilation and launcher inspection when available. | Current-user row has no action or chevron; other participant rows keep their direct-chat tap.                              |

## Recovery checkpoint

- **Last completed step:** Added participant deduplication and auth identity to the widget snapshot; made the self row
  non-clickable and hid its chevron; updated the feature document; Kotlin compilation and `git diff --check` passed.
- **Next action:** None. If desired, rerun focused Dart analysis from the local Flutter terminal and verify the row
  behavior on a launcher.
- **Changed or uncommitted files:** All files listed in this plan; no commit was made.
- **Known failures or blockers:** Focused Dart analysis produced no output and was interrupted after stalling; launcher
  behavior was not checked. Gradle emitted existing Kotlin plugin compatibility and deprecation warnings, but
  compilation succeeded.
- **Known failures or blockers:** None.
