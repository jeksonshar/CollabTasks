# Plan: Picture in Picture for Calls

- **ID:** 0013
- **Status:** Steps 1–4 implemented; focused tests not run; native device verification pending
- **Created:** 2026-11-19
- **Goal:** Keep direct and group calls active when the app is backgrounded and provide a compact call surface with the
  requested controls where the platform supports them.

## Current findings

- `CallsBloc._onAppLifecycleChanged` no longer ends calls on `detached`; call screens request PiP before forwarding
  background lifecycle events to the Bloc.
- Direct video and group screens use the Agora PiP controller and Android audio calls use the native Android PiP bridge.
- iOS background audio is enabled for call continuity. iOS audio-only PiP and app-defined PiP buttons are not supported
  in this implementation.
- The feature documentation maps lifecycle, widget, service, and native PiP behavior to regression tests or a manual
  device scenario.

## Scope

- Preserve an active RTC session and call state while the app moves to the background.
- Provide a compact video or audio call presentation and actions to restore the call, mute/unmute, and end/leave.
- Use native Picture in Picture integration where supported and document platform-specific control limits.
- Add regression tests for lifecycle, compact UI actions, and platform bridge behavior.
- Do not change call persistence schema, backend contracts, or unrelated Android/iOS features.

## Files in scope

| File                                                                          | Intended change                                                                                                                               |
|:------------------------------------------------------------------------------|:----------------------------------------------------------------------------------------------------------------------------------------------|
| `lib/features/calls/ui/blocs/calls_bloc.dart`                                 | Keep active calls alive across background lifecycle events; keep camera behavior consistent with PiP availability and user camera preference. |
| `lib/features/calls/ui/screens/direct/video_call_screen.dart`                 | Enter/exit compact call presentation and preserve the active video surface.                                                                   |
| `lib/features/calls/ui/screens/direct/audio_call_screen.dart`                 | Support compact audio call presentation and restore navigation.                                                                               |
| `lib/features/calls/ui/screens/group/group_call_screen.dart`                  | Support compact group call presentation and map leave/end actions correctly.                                                                  |
| `lib/features/calls/ui/widgets/call_picture_in_picture.dart`                  | Add the shared compact call UI with video/audio presentation and call actions.                                                                |
| `lib/features/calls/data/services/call_picture_in_picture_service.dart`       | Add a Dart platform-channel abstraction for PiP state and actions.                                                                            |
| `android/app/src/main/kotlin/com/example/collab_tasks/MainActivity.kt`        | Handle Android PiP entry, restore, and supported call actions.                                                                                |
| `android/app/src/main/AndroidManifest.xml`                                    | Declare Android PiP activity support.                                                                                                         |
| `lib/di/service_locator.dart`                                                 | Register the PiP service.                                                                                                                     |
| `ios/Runner/Info.plist`                                                       | Enable iOS audio background mode required to continue a call while backgrounded.                                                              |
| `lib/l10n/app_en.arb`                                                         | Add localized compact-call action labels.                                                                                                     |
| `lib/l10n/app_ru.arb`                                                         | Add localized compact-call action labels.                                                                                                     |
| `lib/l10n/app_uk.arb`                                                         | Add localized compact-call action labels.                                                                                                     |
| `test/features/calls/ui/calls_bloc_test.dart`                                 | Cover that pausing/backgrounding no longer ends an active call and retains manual camera/microphone choices.                                  |
| `test/features/calls/ui/video_and_group_call_screens_test.dart`               | Cover compact call rendering and restore/end/leave/mute interactions.                                                                         |
| `test/features/calls/data/services/call_picture_in_picture_service_test.dart` | Add platform-channel service tests for PiP state and actions.                                                                                 |
| `docs/features/calls.md`                                                      | Document lifecycle and PiP behavior, platform limitations, and the behavior-to-test matrix.                                                   |
| `docs/plans/0013-call-picture-in-picture.md`                                  | Track approved steps, acceptance checks, and verification results.                                                                            |
| `docs/memory/handoff.md`                                                      | Point to the active plan and maintain the recovery checkpoint.                                                                                |

No dependency is currently planned. If implementation requires a dependency or expands this file list, request approval
before adding it or editing out-of-scope files.

## Steps

- [x] **Step 1 — Preserve calls across lifecycle changes.** `detached` no longer ends the call; Bloc regression cases
  cover direct video and group audio calls, camera/microphone state, and RTC session retention. Files:
  `lib/features/calls/ui/blocs/calls_bloc.dart`, `test/features/calls/ui/calls_bloc_test.dart`, this plan, and
  `docs/memory/handoff.md`. The focused tests were not run.
- [x] **Step 2 — Shared compact call experience and Dart bridge.** Added the compact video/audio call surface,
  restore/mute/end-or-leave actions, native method/event channel contract, lifecycle entry requests, localized restore
  label, and widget/service regression cases. `flutter gen-l10n` completed; focused tests were not run. Files:
  `lib/features/calls/ui/screens/direct/video_call_screen.dart`,
  `lib/features/calls/ui/screens/direct/audio_call_screen.dart`,
  `lib/features/calls/ui/screens/group/group_call_screen.dart`,
  `lib/features/calls/ui/widgets/call_picture_in_picture.dart`,
  `lib/features/calls/data/services/call_picture_in_picture_service.dart`, `lib/l10n/app_{en,ru,uk}.arb`,
  `test/features/calls/ui/video_and_group_call_screens_test.dart`,
  `test/features/calls/data/services/call_picture_in_picture_service_test.dart`, this plan, and
  `docs/memory/handoff.md`.
- [x] **Step 3 — Native platform integration.** Android now uses the Agora PiP Activity base, supports audio/video PiP
  actions and forwards restore/mute/end-or-leave events. iOS video uses Agora PiP; `Info.plist` enables audio background
  mode so active calls can continue. iOS audio-only PiP and custom mute/end/leave controls are unsupported by
  platform/API constraints. Files: `lib/di/service_locator.dart`,
  `lib/features/calls/data/services/call_picture_in_picture_service.dart`, the three call screens, Android
  `MainActivity.kt` and manifest, iOS `Info.plist`, service/screen tests, this plan, and `docs/memory/handoff.md`.
- [x] **Step 4 — Documentation and acceptance review.** Updated the call feature document with lifecycle/PiP behavior,
  platform limits, data flow, test mapping, and the unrun device scenario. Updated this plan and the handoff. Focused
  tests, analyzer/build checks, and device verification were not run. Files: `docs/features/calls.md`, this plan, and
  `docs/memory/handoff.md`.

## Acceptance checks

- Backgrounding or minimizing the app does not end a connected direct or group call.
- The call remains active until the user ends/leaves it or the remote participant/call ends.
- Video remains available in PiP where the platform and RTC renderer support it; a user's manual camera-off choice is
  preserved.
- Compact audio/video UI shows the available participant information/video and offers restore, microphone mute, and the
  correct direct/group terminal action on supported platforms.
- Restoring PiP opens the corresponding in-app call screen without creating a second RTC session or duplicate call.
- Remote hangup still triggers terminal cleanup while the app is backgrounded.
- The feature document maps each changed behavior-bearing component to a focused test or an explicit manual platform
  scenario.

## Testing matrix

| Component                      | Layer                | Test file(s)                                                                  | Behaviors and cases covered                                                                                                     |
|:-------------------------------|:---------------------|:------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------|
| `CallsBloc` lifecycle handling | Bloc                 | `test/features/calls/ui/calls_bloc_test.dart`                                 | Background/pause does not end active call; manual camera-off and microphone state persist; resume does not duplicate RTC join.  |
| Compact direct/group call UI   | Widget               | `test/features/calls/ui/video_and_group_call_screens_test.dart`               | Video/audio participant presentation, restore, mute, direct end, and group leave actions.                                       |
| PiP platform service           | Data/platform bridge | `test/features/calls/data/services/call_picture_in_picture_service_test.dart` | Method calls, state events, unsupported-platform behavior, and native action forwarding.                                        |
| Native PiP                     | Android/iOS device   | Manual platform scenario                                                      | Enter PiP by minimizing; inspect video/audio surface and supported controls; restore; verify call continuity and remote hangup. |

## Recovery checkpoint

- **Last completed step:** Steps 1–4 are implemented. Android audio/video PiP, system actions, iOS Agora video PiP,
  lifecycle behavior, and feature documentation are updated. `flutter gen-l10n` completed; focused tests, analyzer/build
  checks, and device verification were not run.
- **Next action:** Verify PiP and call continuity on Android and iOS devices, including background microphone/camera
  behavior and platform-specific controls.
- **Changed or uncommitted files:** `lib/features/calls/ui/blocs/calls_bloc.dart`, the three call screens, the new PiP
  service and widget, three call test files, `lib/l10n/app_{en,ru,uk}.arb`, this plan, and `docs/memory/handoff.md`.
- **Known limitations:** iOS audio-only PiP is unsupported; iOS video PiP has no app-defined mute/end/leave buttons.
  Native integrations have not been device-verified. Android video rendering and background microphone behavior must be
  checked on supported OS/device versions.
