# Workflow Handoff

- **Status:** Plan 0015 verification in progress. Android compilation and both focused Flutter PiP tests passed before
  the latest Android 11 compatibility fix. The user reports native PiP labels/actions and direct/group calls passed on
  physical Android 14 and 17. A PiP parameter getter crash was reported on Android 11 and fixed in code; Android Kotlin
  compilation passed, but device verification of that fix is pending. Plan 0014 is complete: direct/group heartbeats and
  leave/remote cleanup passed on physical Android 14 and 17.
- **Active plan:** [
  `docs/plans/0015-android-pip-actions-and-dismissal.md`](../plans/0015-android-pip-actions-and-dismissal.md).
- **Last completed step:** Plan 0015 Steps 1–7 use Android's built-in expand control, synchronize native microphone
  icons with Bloc state, close PiP after call termination, render content-only PiP surfaces, and preconfigure Android
  audio PiP. Audio auto-enters on Android 12+ and uses `onUserLeaveHint` on Android 8–11, with the Flutter lifecycle
  method as fallback. `:app:compileDebugKotlin` passed on 2026-11-26, including Android resource processing and Flutter
  build compilation. Both focused Flutter PiP tests passed in the user's PowerShell. The user reports successful native
  PiP labels/actions and direct/group calls on physical Android 14 and 17 devices, including leaving from PiP. Step 7
  removes API 33-only `PictureInPictureParams` getters from the Android 8–12 path after an Android 11 crash report.
- **Next action:** Install the compiled Android compatibility fix, then verify call acceptance and PiP on Android 11.
  Also verify the Android 8–11 audio PiP path. Plan 0014 is complete; direct/group heartbeat
  timestamps advanced every 15 seconds for over one minute with no errors, and leave/remote cleanup passed. Preserve the
  user's `10:16` aspect ratio,
  `800x1080` content size, and widget label layout.
- **Changed or uncommitted files for plan 0015:** `MainActivity.kt`, `docs/features/calls.md`, the active plan, and this
  handoff include the Android 11 compatibility fix. The user's uncommitted `AGENTS.md` edits are preserved and unrelated
  to Plan 0015.
- **Known limitations:** Android shows custom PiP actions after the user taps the PiP window; Flutter-rendered controls
  are not interactive in PiP on Android or iOS. The Android 11 fix is compiled but not device-verified; Android 8–11
  PiP verification remains pending. Plan 0014's heartbeat
  plan is complete; its 15-second heartbeat and 30-second stale threshold remain unchanged.
- **Previous checkpoints:** Heartbeat correction is tracked in [
  `docs/plans/0014-call-background-retention.md`](../plans/0014-call-background-retention.md). Original PiP integration
  is tracked in [`docs/plans/0013-call-picture-in-picture.md`](../plans/0013-call-picture-in-picture.md).
