# Workflow Handoff

- **Status:** Plan 0015 is complete. The user reports focused home/chat widget tests pass and direct/group PiP call
  termination works without rendering exceptions on physical Android 11, 14, and 17 devices and an Android 9 emulator.
  The Android 14 chat subtitle overflow and remote participant PiP dismissal issue no longer reproduce. The user also
  verified that audio PiP entry works on Android 9–10. Flutter tests repeatedly stalled without output in the agent
  runner, while the user ran them successfully in PowerShell; do not launch tests from the agent runner. Give the exact
  test command and ask the user to run it when verification is needed.
  Plan 0014 is complete: direct/group heartbeats and leave/remote cleanup passed on physical Android 14 and 17.
- **Active plan:** None.
- **Last completed step:** Plan 0015 Steps 1–9 use Android's built-in expand control, synchronize native microphone
  icons with Bloc state, close PiP after call termination, render content-only PiP surfaces, and preconfigure Android
  audio PiP. Audio auto-enters on Android 12+ and uses `onUserLeaveHint` on Android 8–11, with the Flutter lifecycle
  method as fallback. `:app:compileDebugKotlin` passed on 2026-11-26, including Android resource processing and Flutter
  build compilation. Both focused Flutter PiP tests passed before the AppBar change; the user reports the new
  `home_tasks_screen_test.dart` regression test passes. The user reports native PiP labels/actions and call exit on
  Android 14 and 17, and overflow-free direct/group PiP dismissal on Android 11. Step 7 removes API 33-only
  `PictureInPictureParams` getters from the Android 8–12 path after an Android 11 crash report. Step 8 covers the task
  AppBar/status row and compact ChatScreen actions/status subtitle. The user reports focused tests pass and PiP
  termination works on Android 9, 11, 14, and 17, including remote PiP closure on Android 14. Audio PiP entry on
  Android 9–10 is verified. Plan 0015 is complete.
- **Next action:** None. Plan 0015 is complete. Plan 0014 is also complete; direct/group heartbeat timestamps advanced
  every 15 seconds for over one minute with no errors, and leave/remote cleanup passed. Preserve the user's `10:16`
  aspect ratio, `800x1080` content size, and widget label layout.
- **Changed or uncommitted files for plan 0015:** `MainActivity.kt`,
  `lib/features/tasks/ui/screens/home_screen/components/task_app_bar_component.dart`,
  `lib/features/tasks/ui/screens/home_screen/components/task_list_tile.dart`,
  `lib/features/chats/ui/screens/chat_screen.dart`, `test/ui/screens/home_tasks_screen_test.dart`,
  `test/features/chats/ui/chat_screen_test.dart`, `docs/features/calls.md`, the active plan, and this handoff. The
  user's `minSdk = 28` setting is preserved.
- **Known limitations:** Android shows custom PiP actions after the user taps the PiP window; Flutter-rendered controls
  are not interactive in PiP on Android or iOS. Force-stop cleanup and iOS background media remain unverified.
  Plan 0014 is complete; its 15-second heartbeat and 30-second stale threshold remain unchanged.
- **Previous checkpoints:** Heartbeat correction is tracked in [
  `docs/plans/0014-call-background-retention.md`](../plans/0014-call-background-retention.md). Original PiP integration
  is tracked in [`docs/plans/0013-call-picture-in-picture.md`](../plans/0013-call-picture-in-picture.md).
