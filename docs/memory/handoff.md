# Workflow Handoff

- **Status:** Plan 0015 Steps 1–4 implemented; focused Flutter tests and Android/iOS device verification pending. Plan
  0014 Android device verification also remains pending.
- **Active plan:** [
  `docs/plans/0015-android-pip-actions-and-dismissal.md`](../plans/0015-android-pip-actions-and-dismissal.md).
- **Last completed step:** Plan 0015 Steps 1–4 use Android's built-in expand control, synchronize native microphone
  icons with Bloc state, close PiP after call termination, and render content-only PiP surfaces on Android and iOS.
  Removed `showControls`, Flutter PiP action callbacks, and the unused `restoreCall` method. `:app:compileDebugKotlin`
  succeeded before Step 4. Focused Flutter tests were not run in this step; earlier attempts stalled without output.
- **Next action:** Run focused PiP widget tests when the Flutter runner starts normally, then verify Android native
  actions, iOS system PiP restoration, and call-end dismissal on devices. Preserve the user's `10:16` aspect ratio,
  `800x1080` content size, and widget label layout.
- **Changed or uncommitted files for plan 0015:**
  `android/app/src/main/kotlin/com/example/collab_tasks/MainActivity.kt`,
  `android/app/src/main/res/drawable/ic_pip_mic.xml`, `android/app/src/main/res/drawable/ic_pip_mic_off.xml`,
  call PiP service/widget, three call screens, two PiP tests, `docs/features/calls.md`, plan 0015, and this handoff.
  User edits to the PiP service and widget remain intact.
- **Known limitations:** Android shows custom PiP actions after the user taps the PiP window; Flutter-rendered controls
  are not interactive in PiP on Android or iOS. Plan 0014's client heartbeat device verification is still pending; its
  15-second heartbeat and 30-second stale threshold remain unchanged.
- **Previous checkpoints:** Heartbeat correction is tracked in [
  `docs/plans/0014-call-background-retention.md`](../plans/0014-call-background-retention.md). Original PiP integration
  is tracked in [`docs/plans/0013-call-picture-in-picture.md`](../plans/0013-call-picture-in-picture.md).
