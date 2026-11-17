# Plan: Call History Improvements

- **ID:** 0011
- **Status:** Complete
- **Created:** 2026-11-17
- **Goal:** Correct per-user missed-call classification for group calls, protect call-history access with regression
  coverage,
  and improve call-history usability and scalability without changing the call-history data schema.

## Scope

- Treat an incoming call as missed for a recipient who did not connect. Do not distinguish a declined call from an
  unanswered call.
- For group calls, determine whether the current participant connected from that participant's stored call record; do
  not infer their answer from the call-wide `startedAt` value.
- Use `startedAt` to `endedAt` as the duration of the whole call session. Do not include ringing/waiting time and do not
  calculate a per-participant group duration.
- Do not add fields or statuses to distinguish declining from not answering. Existing call and participant data is the
  source for classification.
- Preserve direct-history authorization by querying only Firebase UID/email aliases of the authenticated user and
  filtering the result by the direct-chat opponent.
- Do not deploy Firestore Rules or indexes as part of this plan. Do not add dependencies or a database migration.
- Update the feature documentation test matrix to map the call-history behavior to its tests.

## Files in scope

| File                                                                  | Intended change                                                                                                                              |
|:----------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------|
| `docs/plans/0011-call-history-improvements.md`                        | Track approved scope, steps, checks, and status.                                                                                             |
| `docs/adr/0002-call-history-semantics.md`                             | Record the durable call-history classification and duration decisions as a Proposed ADR.                                                     |
| `docs/memory/handoff.md`                                              | Keep the current plan, last completed step, next action, changed paths, and pending checks. Update after every approved step.                |
| `lib/features/calls/domain/models/call.dart`                          | Classify a terminal group call as missed for an incoming participant who did not join; preserve direct behavior and global session duration. |
| `test/features/calls/domain/call_history_classification_test.dart`    | Cover direct and per-participant group direction/missed classification and session duration.                                                 |
| `test/features/calls/data/firestore_call_repository_test.dart`        | Cover authenticated-identity queries, opponent filtering, and duplicate documents across aliases.                                            |
| `firestore-rules-tests/calls.rules.test.cjs`                          | Cover Direct history query authorization and group-history member/non-member access.                                                         |
| `lib/features/calls/ui/screens/call_history_screen.dart`              | Add retry interaction and use a missed-call error color independently of call direction.                                                     |
| `lib/l10n/app_en.arb`                                                 | Add the history retry label.                                                                                                                 |
| `lib/l10n/app_ru.arb`                                                 | Add the history retry label.                                                                                                                 |
| `lib/l10n/app_uk.arb`                                                 | Add the history retry label.                                                                                                                 |
| `lib/l10n/app_localizations.dart`                                     | Generated localization output from the approved ARB changes; do not edit by hand.                                                            |
| `lib/l10n/app_localizations_en.dart`                                  | Generated localization output from the approved ARB changes; do not edit by hand.                                                            |
| `lib/l10n/app_localizations_ru.dart`                                  | Generated localization output from the approved ARB changes; do not edit by hand.                                                            |
| `lib/l10n/app_localizations_uk.dart`                                  | Generated localization output from the approved ARB changes; do not edit by hand.                                                            |
| `test/features/calls/ui/call_history_screen_test.dart`                | Cover loading error, retry, missed-call icon/color, empty state, and list rendering.                                                         |
| `lib/features/calls/domain/repositories/call_repository.dart`         | Add a paged history contract.                                                                                                                |
| `lib/features/calls/domain/use_cases/get_call_history_use_case.dart`  | Pass page requests and results across the use-case boundary.                                                                                 |
| `lib/features/calls/data/repositories/firestore_call_repository.dart` | Fetch and merge history pages for direct identity aliases or one group.                                                                      |
| `lib/features/calls/data/repositories/in_memory_call_repository.dart` | Keep the in-memory implementation compatible with paged history.                                                                             |
| `lib/features/calls/ui/blocs/call_history_event.dart`                 | Represent initial and subsequent page requests.                                                                                              |
| `lib/features/calls/ui/blocs/call_history_state.dart`                 | Track loaded items, continuation state, and page-loading errors.                                                                             |
| `lib/features/calls/ui/blocs/call_history_bloc.dart`                  | Load and append pages without duplicates or loss of the current list on a page error.                                                        |
| `lib/features/calls/ui/screens/call_history_screen.dart`              | Request the next page as the list approaches its end.                                                                                        |
| `firestore.indexes.json`                                              | Add indexes required by the approved paged queries. Source configuration only; deployment remains separate.                                  |
| `test/features/calls/ui/call_history_bloc_test.dart`                  | Cover first-page, next-page, duplicate-boundary, and page-error transitions.                                                                 |
| `docs/features/calls.md`                                              | Document the final behavior and map each changed behavior-bearing component to tests.                                                        |

## Steps

- [x] **Step 0 — Save planning artifacts only:** Saved this plan, the Proposed ADR, and handoff. No feature source files
  were changed in this step.
- [x] **Step 1 — P1: Per-participant group missed classification:** Updated `Call.isMissedFor` to use the current
  participant record after a call becomes terminal. A participant with no recorded join is missed even if another
  participant joined; a participant with a recorded join is not missed. Declined and unanswered outcomes remain
  combined. Added domain tests for direct/group classification and session duration.
- [x] **Step 2 — P1: Firestore query and Rules regression coverage:** Verified Direct queries use only authenticated
  UID/email aliases, then filter by opponent and deduplicate alias results. Added Rules-emulator cases for Direct and
  group history authorization.
- [x] **Step 3 — P2: Retry and missed-call presentation:** Added localized retry for initial load errors and error
  coloring for missed-call icons, with screen tests. Ran `flutter gen-l10n`; generated outputs were not hand-edited.
- [x] **Step 4 — P2: Paginate long histories:** Added a stable cursor and merged Direct alias query pages, page loading
  across repository/UseCase/Bloc/screen, and required index definitions. Added tests for boundaries, alias overlap,
  ordering, and later-page error recovery. Indexes were not deployed.
- [x] **Step 5 — P2: Documentation and closure:** Updated the calls feature description and behavior-to-test matrix,
  completed this plan, and set the handoff idle after approved checks passed.

## Acceptance checks

- [x] A terminal group call is classified per recipient: a participant who did not connect is missed even when another
  participant connected; a participant who connected is not marked missed.
- [x] Direct calls and group calls do not distinguish “declined” from “unanswered” when the recipient did not connect.
- [x] Group duration remains the whole connected call session, `endedAt - startedAt`; ringing/waiting time and
  per-participant duration are excluded.
- [x] No Firestore fields, participant statuses, dependencies, or migrations are added solely to distinguish declining
  from not answering.
- [x] Direct history tests demonstrate that the query is constrained by current authenticated identities and then
  filtered by the opponent.
- [x] Firestore Rules emulator tests allow members to query only their group history and deny a non-member; no deployed
  Rules or indexes are changed by this plan.
- [x] Retry, missed-call presentation, and pagination behavior have focused screen/Bloc/repository tests.
- [x] `docs/features/calls.md` maps each changed behavior-bearing component to its tests and scenarios.
- [x] Focused Flutter model, repository, Bloc, and screen tests passed; Firestore Rules emulator tests passed;
  `flutter gen-l10n`, `node --check firestore-rules-tests/calls.rules.test.cjs`, index JSON parsing, and
  `git diff --check` passed.
- [x] Checks not run are reported in the handoff. Rules and indexes were not deployed.

## Dependencies

- Step 1 establishes classification semantics used by later screen tests and documentation.
- Step 2 can follow Step 1; it verifies the already-selected data access boundary without changing Rules.
- Step 3 follows the semantics and uses the existing `LoadCallHistory` request parameters for retry.
- Step 4 follows P1 classification and access coverage; its index changes depend on the approved cursor/query design.
- Step 5 follows all implementation and test steps.

## Recovery checkpoint

- **Last completed step:** Step 5 — feature documentation, behavior-to-test matrix, and plan closure completed after the
  approved checks passed.
- **Next action:** None for plan 0011. Firestore Rules and indexes remain source changes only and require a separate
  deployment decision.
- **Changed or uncommitted files:** See the approved file inventory above and the current Git diff; the Proposed ADR
  remains `docs/adr/0002-call-history-semantics.md`.
- **Checks:** Focused model, repository, Bloc, and screen tests passed; Rules emulator suite passed (16 tests);
  `flutter gen-l10n`, JavaScript syntax check, index JSON parsing, and `git diff --check` passed. No Rules or indexes
  were deployed.
- **Known non-blocking tool output:** `flutter gen-l10n` reported two untranslated Ukrainian messages; generation
  completed. `dart format` reported that it could not update a user-level telemetry timestamp; formatting completed.
