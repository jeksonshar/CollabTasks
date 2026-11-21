# Workflow Handoff

- **Status:** Corrected Firestore Rules deployed; Android device verification pending.
- **Active plan:** [`docs/plans/0014-call-background-retention.md`](../plans/0014-call-background-retention.md).
- **Last completed step:** The approved client change uses ID-token email claims and stage-specific, identity-safe
  errors; its repository tests pass. Step 6 replaced `callSnapshot.exists` with `exists(callPath)` in the heartbeat
  Rule, and all 19 Firestore Rules emulator tests pass. Step 7 deployed only the corrected Firestore Rules to
  `collabtasks-fda3f`; Firebase CLI compiled, uploaded, and released them.
- **Next action:** Install a build containing the client change and verify Android PiP beyond 30 seconds. Confirm
  heartbeats succeed and the call remains active. Do not change Functions or the 15-second/30-second timings.
- **Changed or uncommitted files:** `firestore.rules`, `firestore-rules-tests/calls.rules.test.cjs`,
  `lib/features/calls/data/repositories/firestore_call_repository.dart`,
  `test/features/calls/data/firestore_call_repository_test.dart`, `docs/calls-firestore-rules.md`,
  `docs/features/calls.md`, plan 0014, and this handoff.
- **Known limitations:** The fixed client code has not been verified on device. Existing Android foreground
  services/wake locks remain. Force-stop, process death, and network loss still use the current 30-second stale cleanup.
- **Previous checkpoint:** PiP feature implementation is tracked in [
  `docs/plans/0013-call-picture-in-picture.md`](../plans/0013-call-picture-in-picture.md).
