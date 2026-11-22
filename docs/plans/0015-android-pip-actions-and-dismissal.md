# Plan: Android PiP Actions and Call Dismissal

- **ID:** 0015
- **Status:** Steps 1–5 implemented; focused Flutter tests and Android/iOS PiP device verification pending
- **Created:** 2026-11-22
- **Goal:** Make Android call PiP controls match Android's supported interaction model and close the PiP window when a
  call ends.

## Findings

- The shared Flutter call widget draws action buttons inside the PiP content, while Android PiP uses system
  `RemoteAction` controls. Tapping the PiP window opens Android's controls; the Flutter-rendered buttons are not
  interactive there.
- Android presents its custom PiP actions after the user taps the PiP window. The implementation should present only
  these supported native actions while in Android PiP and avoid duplicate-looking Flutter controls.
- The microphone `RemoteAction` currently uses one static system silent-mode icon. `CallPictureInPictureConfiguration`
  and the Android action configuration do not carry or refresh the current microphone mute state.
- The three call screens' `BlocConsumer.listenWhen` predicates do not listen for microphone-state changes, so the PiP
  service is not reconfigured when the user mutes or unmutes.
- Android restore handling remains in the service, MainActivity, and PiP action event model even though Android's
  built-in PiP expand control now restores the activity. The audio PiP method call also sends a map that the native
  entry handler ignores.
- The Flutter call route is popped when call state becomes terminal, but the Android host Activity is not explicitly
  finished while it remains in PiP.
- Flutter controls rendered in the Android PiP activity cannot receive taps; Android actions must use `RemoteAction`.
  Apple's video-call PiP view controller also does not receive touch events, so the shared Flutter action row is not
  a usable iOS PiP control surface either.
- Android audio PiP currently creates its `PictureInPictureParams` only after Flutter receives `hidden` or `paused`.
  The audio parameters do not enable Android 12+ auto-enter, and MainActivity does not enter prepared audio PiP from
  `onUserLeaveHint` on Android 8–11. Video PiP differs: Agora prepares PiP parameters while the call screen is active.
- Preserve the user's local PiP changes: Android aspect ratio `10:16`, preferred content size `800x1080`, and the
  compact widget's current participant-label layout.

## Scope

- Use Android's built-in PiP expand control to restore the call; use native custom actions for microphone toggle and
  direct end/group leave.
- Render participant/video content only in the shared PiP surface on Android and iOS. Android actions use native
  `RemoteAction`; iOS uses the system PiP restore interaction and has no app-defined PiP mute/end controls.
- Close the Android PiP Activity after terminal call cleanup when it is still in PiP. Normal in-app call completion must
  continue to return to the app's previous route.
- Add regression coverage for PiP controls and terminal dismissal bridge behavior, and document the Android interaction
  model.
- Show microphone enabled/muted state through distinct native microphone icons and matching action labels, updating
  the existing PiP action when `CallsBloc` state changes without restarting the call foreground service.
- Remove the obsolete custom restore action/bridge/event path, unused audio PiP method arguments, and unused avatar
  field from the PiP service configuration. Keep the cleanup limited to call PiP code.
- Prepare Android audio PiP parameters while the call remains active. Enable system auto-enter on Android 12+ and enter
  from `onUserLeaveHint` on Android 8–11, retaining the Dart lifecycle-triggered method as an idempotent fallback.
- Do not change Firestore rules, heartbeat intervals, call persistence, dependencies, or the user's aspect ratio and
  preferred dimensions.

## Files in scope

| File                                                                          | Intended change                                                                                                   |
|:------------------------------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------|
| `android/app/src/main/kotlin/com/example/collab_tasks/MainActivity.kt`        | Handle PiP dismissal; update microphone action icon/label; prepare audio PiP auto-enter and legacy entry.         |
| `android/app/src/main/res/drawable/ic_pip_mic.xml`                            | Add the enabled-microphone system action icon.                                                                    |
| `android/app/src/main/res/drawable/ic_pip_mic_off.xml`                        | Add the muted-microphone system action icon.                                                                      |
| `lib/features/calls/data/services/call_picture_in_picture_service.dart`       | Add mute-state updates; prepare audio PiP before backgrounding; remove stale restore bridge, payload, and avatar. |
| `lib/features/calls/ui/widgets/call_picture_in_picture.dart`                  | Render PiP participant/video content without noninteractive Flutter action controls.                              |
| `lib/features/calls/ui/screens/direct/video_call_screen.dart`                 | Remove Flutter PiP action controls and their callbacks; forward mute changes.                                     |
| `lib/features/calls/ui/screens/direct/audio_call_screen.dart`                 | Remove Flutter PiP action controls and their callbacks; forward mute changes.                                     |
| `lib/features/calls/ui/screens/group/group_call_screen.dart`                  | Remove Flutter PiP action controls and their callbacks; forward mute changes.                                     |
| `test/features/calls/ui/video_and_group_call_screens_test.dart`               | Cover content-only shared PiP rendering and forwarding Bloc mute changes into PiP configuration.                  |
| `test/features/calls/data/services/call_picture_in_picture_service_test.dart` | Cover early audio PiP preparation, PiP dismissal, and microphone state refresh without service restart.           |
| `docs/features/calls.md`                                                      | Document system PiP controls, microphone state icon, PiP dismissal, and audio PiP entry timing.                   |
| `docs/plans/0015-android-pip-actions-and-dismissal.md`                        | Track implementation, acceptance, and verification.                                                               |
| `docs/memory/handoff.md`                                                      | Record the active plan and recovery checkpoint.                                                                   |

## Steps

- [x] **Step 1 — Implement Android PiP controls and dismissal.** Android PiP hides the Flutter action row, uses the
  system's built-in expand control rather than a duplicate restore action, and retains native `RemoteAction` controls
  for microphone and end/leave. Call-service teardown requests native dismissal; the Activity finishes only if it
  remains in PiP. Added regression cases for hidden Flutter controls and the native dismissal bridge. Tests were not
  run. Files: `MainActivity.kt`, the PiP service, shared PiP widget, three call screens, both PiP test files, this plan,
  and `docs/memory/handoff.md`.
- [x] **Step 2 — Sync feature documentation and verify.** Updated call documentation with Android PiP system controls,
  the built-in expand action, and Activity dismissal after call termination. Attempted both focused Flutter test files
  using PowerShell and `cmd.exe`; both runner invocations stalled without output and were interrupted, so test results
  are unavailable. Native Android device verification remains pending. Files: `docs/features/calls.md`, this plan, and
  `docs/memory/handoff.md`.
- [x] **Step 3 — Reflect microphone state and remove stale PiP paths.** Send the initial and changed microphone state
  to MainActivity, refresh the native PiP action icon/label without restarting the foreground service, add enabled and
  muted vector icons, and remove the obsolete custom restore action/bridge/event plus unused audio-entry arguments.
  Added service and screen regression cases; tests are pending. Files: `MainActivity.kt`, `ic_pip_mic.xml`,
  `ic_pip_mic_off.xml`, the PiP service, three call screens, both PiP test files, `docs/features/calls.md`, this plan,
  and
  `docs/memory/handoff.md`.
- [x] **Step 4 — Make the shared PiP surface content-only.** Removed `showControls`, the Flutter action row, and its
  callbacks from the shared PiP widget and all three call screens. Android continues to expose native `RemoteAction`
  controls and its built-in expand action; iOS uses system PiP restoration and does not show app-defined PiP mute/end
  controls. Replaced obsolete widget-action assertions with content-only PiP coverage, kept mute forwarding coverage,
  and updated feature documentation. Focused tests were not run. Files: shared PiP widget, three call screens, PiP
  service (`restoreCall` removed), screen test, `docs/features/calls.md`, this plan, and `docs/memory/handoff.md`.
- [x] **Step 5 — Prepare Android audio PiP before minimizing.** Configure and store native audio PiP parameters while
  the call is active. Set `autoEnterEnabled` for Android 12+ and use `onUserLeaveHint` to enter on Android 8–11. Keep
  the existing lifecycle method call as an idempotent fallback and report success if native PiP already started.
  Updated the service channel test and documented the version-specific entry path. Tests and device verification were
  not run. Files: `MainActivity.kt`, `call_picture_in_picture_service.dart`,
  `test/features/calls/data/services/call_picture_in_picture_service_test.dart`, `docs/features/calls.md`, this plan,
  and `docs/memory/handoff.md`.

## Acceptance checks

- Android PiP shows the remote call content without Flutter-rendered buttons that appear interactive but cannot receive
  PiP taps; the shared PiP widget has no app-defined action row on Android or iOS.
- Android's built-in expand control restores the call; native custom actions toggle the microphone and end a direct call
  or leave a group call without a duplicate restore action.
- The native microphone action visibly distinguishes enabled from muted state and stays synchronized with successful
  Bloc mute changes for direct audio/video and group calls.
- Updating the microphone action does not restart the Android call foreground service or alter PiP aspect/dimensions.
- Android audio calls prepare PiP parameters before the app backgrounds; Android 12+ uses system auto-enter and
  Android 8–11 enter from `onUserLeaveHint`. The lifecycle fallback recognizes an Activity already in PiP.
- No obsolete custom Android restore action, restore event handling, ignored audio PiP configuration payload, or
  unused avatar field in the service configuration remains.
- A terminal call state closes the PiP window; the native dismissal is limited to the case where the host Activity is
  still in PiP.
- Ending a call while not in PiP preserves the existing in-app navigation behavior.
- The user's `10:16` aspect ratio, `800x1080` preferred content size, and widget layout edit remain intact.
- Focused tests cover the changed bridge and UI behavior; a manual Android device scenario verifies first-tap
  system-control presentation, each native action, and remote/local call termination.

## Testing matrix

| Component                   | Layer                | Test file(s)                                                                  | Behaviors and cases                                                                                                                         |
|:----------------------------|:---------------------|:------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------|
| Compact PiP content         | Widget               | `test/features/calls/ui/video_and_group_call_screens_test.dart`               | Shared PiP renders call content without app-defined action controls; Android native actions remain available.                               |
| PiP service teardown        | Data/platform bridge | `test/features/calls/data/services/call_picture_in_picture_service_test.dart` | Native PiP dismissal is requested on close and service cleanup remains safe.                                                                |
| PiP microphone action state | Data/platform bridge | `test/features/calls/data/services/call_picture_in_picture_service_test.dart` | Initial and changed mute state updates the native PiP action without restarting the foreground service.                                     |
| Call screen mute forwarding | Widget               | `test/features/calls/ui/video_and_group_call_screens_test.dart`               | Bloc microphone changes trigger a PiP service configuration update.                                                                         |
| Native PiP                  | Android device       | Manual platform scenario                                                      | Verify audio PiP entry on Android 8–11 and 12+; verify system controls, video PiP, and PiP dismissal after local or remote call completion. |

## Recovery checkpoint

- **Last completed step:** Steps 1–5 implemented and documented. `:app:compileDebugKotlin` succeeded after Step 5,
  including Flutter build compilation. Focused Flutter tests from earlier steps repeatedly stalled without output and
  were interrupted; the updated audio PiP service test was not run. Native device verification remains pending.
- **Next action:** Run the focused audio PiP service test when the Flutter runner starts normally, then verify audio PiP
  entry on Android 8–11 and Android 12+ devices.
- **Changed or uncommitted files:** `android/app/src/main/kotlin/com/example/collab_tasks/MainActivity.kt`,
  `android/app/src/main/res/drawable/ic_pip_mic.xml`, `android/app/src/main/res/drawable/ic_pip_mic_off.xml`,
  `lib/features/calls/data/services/call_picture_in_picture_service.dart`, the shared PiP widget, three call screens,
  both PiP test files, `docs/features/calls.md`, this plan, and `docs/memory/handoff.md`. User edits to PiP dimensions
  and widget label layout are preserved.
- **Known limitations:** Android requires a tap on the PiP window to reveal native controls. Neither Android nor the
  iOS video-call PiP surface supports tappable Flutter-rendered controls. Focused test results and device verification
  are pending.
