# Plan: Fix Call Heartbeat Permission Denial

- **ID:** 0014
- **Status:** Corrected Rules deployed; Android device verification pending
- **Created:** 2026-11-19
- **Goal:** Keep calls active by allowing the authenticated connected participant's heartbeat write to target the same
  document key that Firestore Rules authorize.

## Findings

- Device logs from a reproduced Android video call show `CallLiveness` heartbeat writes failing every 15 seconds with
  `cloud_firestore/permission-denied`.
- The call connects at 23:44:08, the first failed heartbeat appears at 23:44:23, and Firestore reports `status=ended` at
  23:44:38. This timing matches the existing 30-second server stale threshold.
- The user clarified that no deployment had been performed. Project configuration targets Firebase project
  `collabtasks-fda3f`; its only database is `(default)` Standard. A Rules-only deployment was then run successfully. The
  CLI compiled `firestore.rules`, reported the latest version was already up to date and skipped uploading it, then
  released the rules. The deployed rules therefore already matched the checked-in file.
- The heartbeat rule selects the participant key by preferring the authenticated email key when present and otherwise
  using Firebase UID (`participantKeyFor`). `FirestoreCallRepository.updateParticipantHeartbeat` previously chose the
  write path from the decoded `CallParticipant.userId`. If that differed from the map key selected by the rule, the
  heartbeat write was denied even though the participant was connected. The client correction is implemented; verify it
  using an installed build that contains the correction.
- The CallKit-service wake lock and the app-owned Android call foreground service did not resolve the permission denial.
  CPU scheduling is not the cause shown by this trace.
- After the user installed a build with the client correction, logs still showed `PERMISSION_DENIED` at 16:44:00 and
  16:44:15; the RTC client left the channel at 16:44:15. The Rules-only deployment compiled and released the rules but
  skipped upload because the server version already matched the checked-in file.
- The current client selects the email key from `FirebaseAuth.currentUser.email`; Rules select it from the ID-token
  claim
  `request.auth.token.email`. These normally match, but the code does not guarantee that the cached `User.email` and
  token claim are identical. This is a hypothesis to validate, not a confirmed cause.
- `updateParticipantHeartbeat` reads the call document and writes the heartbeat within one transaction. The liveness
  coordinator logs any transaction error as a heartbeat failure, so current logs do not identify whether the parent read
  or heartbeat write was denied. Existing Firestore Rules emulator tests do not cover heartbeat create/update
  authorization.
- The new Rules emulator tests now reproduce the live denial: heartbeat create and update fail at
  `connectedHeartbeatOwner()` with `Property exists is undefined on object` for `callSnapshot.exists`. Firestore Rules
  require `exists(callPath)` for document existence checks; the `get(callPath)` result is accessed through `.data`.
  This is the confirmed cause of heartbeat `PERMISSION_DENIED` in the checked-in/deployed Rules. The earlier token-email
  mismatch was a useful hardening concern, but it is not required to explain this failure.

## Implemented correction

`FirestoreCallRepository.updateParticipantHeartbeat` now derives the heartbeat document ID from the raw
`participantsByUser` map using the same email-first, UID-fallback selection as `participantKeyFor`. It confirms the
selected entry matches the map key and is connected before writing. `firestore.rules`, the 15-second heartbeat interval,
and the 30-second stale threshold remain unchanged.

## Exact implementation file scope

| File                                                                  | Intended change                                                                                                              |
|:----------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------|
| `lib/features/calls/data/repositories/firestore_call_repository.dart` | Choose and validate the heartbeat document key using the same authenticated email/UID precedence as Firestore Rules.         |
| `docs/calls-firestore-rules.md`                                       | Document that the client heartbeat path must match `participantKeyFor` and that rules only permit connected self-heartbeats. |
| `docs/features/calls.md`                                              | Document the 15-second client heartbeat, 30-second stale threshold, and identity-key alignment.                              |
| `docs/plans/0014-call-background-retention.md`                        | Track the approved correction and verification state.                                                                        |
| `docs/memory/handoff.md`                                              | Record this diagnosis and the pending implementation approval.                                                               |

The checked-in and deployed `firestore.rules` already include the heartbeat permission. The revised implementation will
read the email from Firebase ID-token claims, distinguish call-document read failures from heartbeat-write failures
without logging raw identifiers, and add client and Rules regression coverage. No Rules source edit, threshold change,
Cloud Function change, or deployment is in scope. If verification shows that a Rules or server change is needed, prepare
a new file scope and obtain separate approval. The user must approve the implementation step before code or test files
are changed.

## Revised client implementation file scope (completed Step 5)

| File                                                                  | Intended change                                                                                                               |
|:----------------------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------|
| `lib/features/calls/data/repositories/firestore_call_repository.dart` | Select email from the Firebase ID-token claim, distinguish call-read from heartbeat-write errors, and log no raw identifiers. |
| `test/features/calls/data/firestore_call_repository_test.dart`        | Cover email/UID key selection and stage-specific heartbeat failures.                                                          |
| `firestore-rules-tests/calls.rules.test.cjs`                          | Cover allowed heartbeat create/update and denied unauthorized writes.                                                         |
| `docs/calls-firestore-rules.md`                                       | Document ID-token claim selection and heartbeat Rules test coverage.                                                          |
| `docs/features/calls.md`                                              | Document the 15-second heartbeat, 30-second stale threshold, and verified identity behavior.                                  |
| `docs/plans/0014-call-background-retention.md`                        | Track this diagnosis, approved implementation scope, and verification.                                                        |
| `docs/memory/handoff.md`                                              | Record the current diagnosis and next approved step.                                                                          |

## Rules correction file scope (approved Step 6)

| File                                           | Intended change                                                                                                                                                          |
|:-----------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `firestore.rules`                              | Replace the invalid `callSnapshot.exists` property check with the Rules `exists(callPath)` function while retaining the connected participant and timestamp constraints. |
| `firestore-rules-tests/calls.rules.test.cjs`   | Keep the new email-key, UID-key, wrong-alias, stranger, and refresh cases as regression coverage; require all to pass.                                                   |
| `docs/calls-firestore-rules.md`                | Record the corrected existence check and successful heartbeat authorization behavior.                                                                                    |
| `docs/features/calls.md`                       | Update the heartbeat test matrix to reflect passing Rules coverage.                                                                                                      |
| `docs/plans/0014-call-background-retention.md` | Track the confirmed cause, approved Rules fix, and verification state.                                                                                                   |
| `docs/memory/handoff.md`                       | Record the confirmed cause and pending Rules fix approval.                                                                                                               |

No Cloud Function or heartbeat/stale threshold change is planned. Publishing a corrected `firestore.rules` is a separate
operation that requires explicit approval after implementation and validation.

## Steps

- [x] **Step 1 — Keep Android CPU awake in the CallKit service.** Added a partial wake lock to the CallKit plugin
  foreground service. User reported no improvement.
- [x] **Step 2 — Add app-owned Android foreground service.** Added a service and wake lock for every active Android RTC
  call. User reported no improvement. Device logs subsequently showed the actual failure is Firestore permission denial
  on heartbeat writes.
- [x] **Step 3 — Align client heartbeat key with published Rules.** The repository now uses the raw participant map and
  the same email-first/UID-fallback key selection as Rules. Updated the Rules documentation and feature documentation.
  Tests/build checks were not run. Files: `lib/features/calls/data/repositories/firestore_call_repository.dart`,
  `docs/calls-firestore-rules.md`, `docs/features/calls.md`, this plan, and `docs/memory/handoff.md`.
- [x] **Step 4 — Release Firestore Rules.** With user approval, ran a Rules-only deployment to project
  `collabtasks-fda3f`. The rules compiled and were released; the CLI reported that the deployed rules were already up to
  date and skipped uploading a new version. No Functions, Hosting, or indexes were deployed.
- [x] **Step 5 — Apply the revised client fix and regression coverage.** Under the user's implementation approval, use
  the
  ID-token email claim for email-first/UID-fallback key selection, distinguish parent-read and heartbeat-write errors
  without exposing raw identifiers, add repository and Firestore Rules tests, and sync the technical documentation. Run
  the approved focused checks. Repository tests pass; Firestore Rules tests exposed the `callSnapshot.exists` defect.
  Files: `lib/features/calls/data/repositories/firestore_call_repository.dart`,
  `test/features/calls/data/firestore_call_repository_test.dart`, `firestore-rules-tests/calls.rules.test.cjs`,
  `docs/calls-firestore-rules.md`, `docs/features/calls.md`, this plan, and `docs/memory/handoff.md`.
- [x] **Step 6 — Correct the Firestore Rules.** Under the user's approval, use `exists(callPath)` instead of
  `callSnapshot.exists` in `connectedHeartbeatOwner()`. The Firestore Rules emulator suite passed all 19 tests. Files:
  `firestore.rules`, `firestore-rules-tests/calls.rules.test.cjs`, `docs/calls-firestore-rules.md`,
  `docs/features/calls.md`, this plan, and `docs/memory/handoff.md`.
- [x] **Step 7 — Deploy corrected Rules.** With user approval, deployed only Firestore Rules to `collabtasks-fda3f`.
  Firebase CLI compiled, uploaded, and released `firestore.rules`; Functions, Hosting, and indexes were not deployed.
- [ ] **Step 8 — User-device verification.** Install a build containing the approved client change, reproduce an Android
  PiP call beyond 30 seconds, and confirm successful heartbeat writes and active call state. Verify direct/group calls
  and remote hangup. If permission denial remains, use the stage-specific logs to determine whether a later change
  belongs
  to Rules or the client.

## Acceptance checks

- Heartbeat document key selection exactly matches the Rules' email-first, UID-fallback selection.
- A heartbeat is written only for the authenticated participant's connected map entry.
- Client selection uses the authenticated ID-token email claim used by Rules, not a potentially stale `User.email`
  value.
- Logs distinguish denial while reading the call document from denial while writing the heartbeat and do not print raw
  email or UID values.
- Repository tests cover email-key and UID-key selection; Rules emulator tests cover allowed heartbeat creation/update
  and denied unauthorized writes.
- Firestore Rules and the 15-second/30-second liveness timings remain unchanged.
- Device logs show successful heartbeat writes during PiP and no permission-denied errors; call remains active beyond 30
  seconds.
- Remote hangup and explicit end/leave still trigger existing cleanup.

## Verification

- **Observed:** Device log trace confirms heartbeat permission-denied precedes server `ended` status by the existing
  30-second window.
- **Repository test:** `flutter test test/features/calls/data/firestore_call_repository_test.dart` passed (22 tests).
- **Rules emulator:** The initial run had 16 passes and 3 heartbeat failures, confirming the invalid
  `callSnapshot.exists` access. After changing the existence check to `exists(callPath)`,
  `firebase emulators:exec --only firestore --project demo-collabtasks-rules "npm --prefix firestore-rules-tests test"`
  passed all 19 tests.
- **Manual:** The user's latest device attempt before the Rules correction produced `PERMISSION_DENIED`. Verify again
  after the corrected Rules are deployed and the client build is installed.
- **Deployment:** The initial Rules-only deployment found the server already matched the then-checked-in file and
  skipped upload. After the approved `callSnapshot.exists` correction, a second Rules-only deployment to
  `collabtasks-fda3f` compiled, uploaded, and released the corrected file. No Functions, Hosting, or indexes were
  deployed.

## Recovery checkpoint

- **Last completed step:** Client ID-token key selection and stage-specific errors are implemented; the repository test
  suite passes. Step 6 corrected the heartbeat parent existence check to `exists(callPath)`. The Firestore Rules
  emulator
  suite passes all 19 tests, including email/UID key paths and denied wrong-alias/stranger writes.
- **Next action:** Install a build containing the client change and verify Android PiP beyond 30 seconds against the
  corrected deployed Rules. Confirm heartbeats succeed and the call remains active. Do not change Cloud Functions or
  heartbeat/stale intervals.
- **Known limitations:** Device evidence covers one Android direct video call. Direct/group audio/video and iOS behavior
  still need verification after the correction.
