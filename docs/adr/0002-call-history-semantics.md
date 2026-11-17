# ADR 0002: Call History Classification and Duration

- **Status:** Proposed
- **Date:** 2026-11-17
- **Supersedes:** None
- **Superseded by:** None

## Context

Call history displays records for both direct and group calls. A group call document has call-wide `startedAt` and
`endedAt` values, while each participant record has its own status and optional `joinedAt`. A call-wide start time only
proves that at least one participant joined; it does not prove that every invitee connected. The call document does not
store a separate duration for each group participant.

## Decision

- Treat an incoming call as missed for a recipient who did not connect. Do not distinguish a declined call from an
  unanswered call in call history.
- For a terminal group call, classify each recipient using that recipient's stored participant record. A participant
  without a recorded join is missed even when another participant connected. A participant with a recorded join is not
  missed merely because they left before the group call ended.
- Keep call duration at the session level: `endedAt - startedAt`. Exclude time spent ringing/waiting and do not
  calculate
  an individual participation duration for group members.
- Reuse existing call and participant data. Do not add fields or statuses solely to distinguish declining from not
  answering or to store per-participant group duration.
- If a legacy participant record lacks enough information to determine whether that user joined, do not infer a missed
  call from the call-wide `startedAt` alone.

## Consequences

- A group call can be shown as missed for one invitee and answered for another.
- Missed and declined calls share the same history label by design.
- Group members see the same overall session duration; the duration does not represent their personal time in the call.
- No migration is required. A legacy record with missing start/end timestamps has no calculable connected duration.

## Alternatives considered

- Use the call-wide `startedAt` to classify every group recipient: rejected because it marks every invitee as answered
  when only one person connected.
- Add a distinct participant status or outcome field for “declined” and “unanswered”: rejected because the requested
  history intentionally combines both cases.
- Persist per-participant duration or leave time: rejected because the requested duration is the group session duration,
  not each participant's attendance time.
