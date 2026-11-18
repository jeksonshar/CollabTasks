# Plan: Groups Widget Reliability and Scalability

- **ID:** 0012
- **Status:** Steps 1–2 complete; Step 3 reverted per user request
- **Created:** 2026-11-17
- **Goal:** Improve GroupsWidget navigation delivery reliability, add automated coverage for Flutter synchronization and
  routing, and make expanded group content scale to larger participant/task lists.

## Review findings

- `MainActivity.onNewIntent` forwards a groups navigation request to Flutter and clears its intent extras immediately.
  Unlike cold-start navigation, the warm-start path has no acknowledgement or durable pending request if the Dart
  handler is not ready or delivery fails. This is a code-path risk; it was not reproduced during the read-only review.
- Existing GroupsWidget Flutter tests cover bridge snapshot serialization and initial navigation parsing, but do not
  cover inbound channel events, stream subscription lifecycle, or routes opened by the widget.
- The Glance `LazyColumn` virtualizes groups, while participant and task rows inside an expanded group are emitted with
  eager `forEach` calls. A large group can therefore create a large widget view tree.

## Scope

- Add focused tests for the groups MethodChannel and Flutter widget listener, including synchronization and navigation.
- Define and implement replayable Android-to-Flutter navigation delivery with acknowledgement and duplicate handling.
- Virtualize expanded group sections while preserving section ordering and the single scroll experience.
- Update the GroupsWidget feature test matrix and recovery documentation.
- Do not change personal-task widget behavior, group business rules, or persistence schemas.

## Files in scope

| File                                                                                      | Intended change                                                                                                                                                          |
|:------------------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `test/features/working_groups/data/widgets/groups_widget_bridge_test.dart`                | Extend channel tests for incoming navigation delivery and acknowledgement contract.                                                                                      |
| `test/features/working_groups/ui/widgets/groups_widget_bloc_listener_test.dart`           | Add tests for group/participant/task stream snapshots, deletion, route dispatch, and subscription cleanup.                                                               |
| `lib/features/working_groups/data/widgets/groups_widget_bridge.dart`                      | Implement the Dart side of the acknowledged navigation contract.                                                                                                         |
| `lib/features/working_groups/ui/widgets/groups_widget_bloc_listener.dart`                 | Handle replayed navigation safely and verify stream lifecycle and routing.                                                                                               |
| `android/app/src/main/kotlin/com/example/collab_tasks/MainActivity.kt`                    | Retain pending widget navigation until Flutter acknowledges consumption.                                                                                                 |
| `android/app/src/main/kotlin/com/example/collab_tasks/GroupsWidgetNavigationStore.kt`     | Add a small native store for pending navigation payloads and acknowledgement.                                                                                            |
| `android/app/src/test/kotlin/com/example/collab_tasks/GroupsWidgetNavigationStoreTest.kt` | Test native pending-event storage, replay, and acknowledgement behavior.                                                                                                 |
| `android/app/src/main/kotlin/com/example/collab_tasks/GroupsHomeGlanceWidget.kt`          | Render expanded group rows through a flattened lazy list.                                                                                                                |
| `android/app/src/main/kotlin/com/example/collab_tasks/GroupsWidgetContentModel.kt`        | Add a testable model that flattens groups and expanded sections into ordered lazy rows.                                                                                  |
| `android/app/src/test/kotlin/com/example/collab_tasks/GroupsWidgetContentModelTest.kt`    | Test collapsed/expanded row composition and participant-before-task ordering.                                                                                            |
| `android/app/build.gradle.kts`                                                            | Configure the local Kotlin test dependency if required by the native unit tests. Any dependency addition will be called out for explicit approval before implementation. |
| `docs/adr/0003-groups-widget-navigation-delivery.md`                                      | Record the durable Android/Flutter navigation delivery contract as Proposed.                                                                                             |
| `docs/features/android_groups_widget.md`                                                  | Map automated tests and manual launcher scenarios to the behaviors they cover.                                                                                           |
| `docs/plans/0012-groups-widget-review.md`                                                 | Track implementation steps, acceptance checks, and verification results.                                                                                                 |
| `docs/memory/handoff.md`                                                                  | Point to the active plan and maintain the recovery checkpoint.                                                                                                           |

## Steps

- [x] **Step 1 — Flutter behavior tests and feature matrix.** Added bridge/listener regression tests and mapped coverage
  in the feature document. Files: the two Flutter test files above, `docs/features/android_groups_widget.md`, this plan,
  and `docs/memory/handoff.md`.
- [x] **Step 2 — Reliable navigation delivery.** Add native pending-event storage and acknowledgement, connect it to the
  Flutter bridge/listener, and add focused native tests. Files: `MainActivity.kt`, `GroupsWidgetNavigationStore.kt`,
  `GroupsWidgetNavigationStoreTest.kt`, `android/app/build.gradle.kts` only if a test dependency is needed, both Flutter
  bridge/listener files, the ADR, this plan, and handoff.
- [ ] **Step 3 — Lazy expanded content.** Deferred. The flattened expanded-row layout was reverted per user request; the
  original single rounded group card layout with eager participant/task rows is restored.

## Dependencies

- Step 1 precedes Step 2 because it establishes Flutter-side regression coverage for the navigation and listener
  behavior.
- Step 3 is independent of the navigation contract, but follows Step 1 so both platform checks can share the updated
  feature test matrix.
- ADR 0003 is Proposed and documents the delivery semantics before the Step 2 implementation. It must remain Proposed
  unless the user explicitly accepts it.
- If native test dependencies are needed, request explicit approval before adding them.

## Acceptance checks

- [x] Widget navigation survives Flutter startup timing and is removed from the pending store only after
  acknowledgement.
- [x] Replayed navigation does not open duplicate routes during one active app session; duplicate warm delivery and
  bridge payload parsing are covered. Native cold-start/warm-start lifecycle is compile-verified but not device-tested.
- [x] Flutter tests cover incoming bridge events, synchronization on stream updates/removals, expected navigation
  destinations, and subscription disposal.
- [ ] Expanded groups render participants before tasks in one lazy scroll list; collapsed groups render only their group
  row.
- [ ] Kotlin tests cover lazy-row composition/order and Glance item IDs.
- [x] `docs/features/android_groups_widget.md` maps each automated case and clearly lists remaining device-only checks.
- [x] Focused Flutter tests (12), all Kotlin unit tests, `:app:compileDebugKotlin`, and `git diff --check` pass.
  Launcher behavior remains device-only and unverified.

## Testing matrix

| Component                         | Layer            | Test file(s)                                                                                                                                                | Behaviors and cases covered                                                                                                       |
|:----------------------------------|:-----------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------|:----------------------------------------------------------------------------------------------------------------------------------|
| Groups widget bridge and listener | Data / UI        | `test/features/working_groups/data/widgets/groups_widget_bridge_test.dart`; `test/features/working_groups/ui/widgets/groups_widget_bloc_listener_test.dart` | Incoming navigation, acknowledgement, snapshot streams, group removal, route dispatch, and subscription cleanup.                  |
| Native groups navigation store    | Android platform | `android/app/src/test/kotlin/com/example/collab_tasks/GroupsWidgetNavigationStoreTest.kt`                                                                   | Pending request persistence, replay, and removal after acknowledgement.                                                           |
| Glance provider and launcher      | Android device   | Manual Android launcher scenario                                                                                                                            | Cold/warm widget taps, background/participant/task navigation, scrolling large groups, and coexistence with personal task widget. |

## Recovery checkpoint

- **Last completed step:** Step 3's flattened row layout was reverted per user request. The original rounded
  `GroupWidgetSection` card and 8 dp group spacing are restored. Navigation store tests and `:app:compileDebugKotlin`
  passed after the rollback; launcher visuals were not checked because no device was connected.
- **Next action:** None for the requested rollback. Step 3 remains deferred unless requested again.
- **Changed or uncommitted files:** Step 1–2 files from the review remain; Step 3's content model, model tests, and
  shape resources were removed. The GroupsWidget feature document, plan 0012, and handoff reflect the rollback. ADR 0003
  remains Proposed.
- **Known failures or blockers:** Launcher visuals are not verified on-device. Flutter/Dart analyzer commands previously
  stalled and have no result. Gradle reports existing Kotlin/Gradle deprecation warnings. Newest-tap-wins applies when
  multiple navigation requests are pending.
