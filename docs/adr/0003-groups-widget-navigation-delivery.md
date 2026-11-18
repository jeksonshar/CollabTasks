# ADR 0003: Groups Widget Navigation Delivery

- **Status:** Proposed
- **Date:** 2026-11-17
- **Supersedes:** None
- **Superseded by:** None

## Context

GroupsWidget taps start or resume `MainActivity` and pass navigation data from Android to Flutter. Cold-start requests
are read from the activity intent, while warm-start requests are sent over a MethodChannel. The current warm-start
handler clears the intent extras immediately after dispatch and has no acknowledgement path. If Flutter is not ready to
handle the event, the request may be lost. Widget navigation is an external boundary between the launcher, Android, and
Flutter, so its delivery behavior must be explicit.

## Decision

- Keep a pending groups-widget navigation request in native app storage until Flutter confirms it has accepted the
  request for handling.
- Deliver pending requests on both cold and warm starts through the same bridge contract.
- Give each request an identifier. Flutter ignores duplicate delivery of a request already accepted during the active
  app session and acknowledges a request only after it has been handed to the route handler.
- Keep one pending request; a newer widget tap replaces an older unacknowledged request. This makes the most recent
  user action the one replayed after startup.
- Treat delivery as at-least-once across process interruption. A request may be replayed if the process ends before
  acknowledgement; the identifier makes this replay detectable.
- Keep personal-task widget navigation on its existing channel and contract.

## Consequences

- A widget tap is less likely to disappear during Flutter engine startup or recreation.
- Android and Flutter share an acknowledgement and request-identity contract that must stay covered by tests.
- A request can be replayed after process interruption before acknowledgement; route handling must be idempotent for
  duplicate request identifiers.
- If several widget taps arrive before acknowledgement, only the latest pending tap is retained.
- No group/task persistence schema changes are required; pending navigation is short-lived application state.

## Alternatives considered

- Clear intent extras immediately after sending a warm-start MethodChannel event: rejected because the Dart handler may
  not be ready and there is no recovery path.
- Rely only on the initial activity intent: rejected because it does not cover activity reuse and warm-start delivery.
- Use exactly-once delivery: rejected because process interruption between route handling and native acknowledgement
  makes exactly-once behavior unavailable without a transactional protocol across both runtimes.
