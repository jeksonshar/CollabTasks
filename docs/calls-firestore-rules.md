# Firestore rules for calls

## Data and identity assumptions

Call documents use the fields serialized by `Call.toMap()` and participant fields serialized by `CallParticipant.toMap()`. Participants are stored in `participantsByUser`, a map keyed by participant identity. Emails are trimmed and lowercased; Firebase UIDs are trimmed but remain case-sensitive. `Call.fromMap()` converts the keyed map back to the domain list; it can still read legacy `participants` arrays, but new writes use only `participantsByUser`. Rules match either the authenticated Firebase UID or lowercased Auth email. Incoming-call listeners query `calleeIds` with `arrayContains` and `status` with equality for both `ringing` and `active`.

The caller may start a call and cancel a ringing call. The caller or a connected participant in an active group call may invite one participant at a time. Re-inviting a `left` or `declined` participant returns only that participant's keyed record to `ringing`. A callee may accept or reject their own ringing record. This supports accepting invitations to an active group call while preserving the call's active status and immutable call metadata. Any call member may end or leave a call. Clients cannot delete call documents.

## Participant map and aggregate transitions

Rules compare `participantsByUser.diff()` and require exactly one changed key for participant transitions. The changed key must match the authenticated user's UID or email, and that record's diff is restricted to the fields for the transition. Invites use `lastInvitedParticipantId` to identify the single map key changed by the caller. Caller-only creation still supplies the initial invited participant map; the caller cannot create a call on behalf of another caller.

Rules cannot iterate the participant map to determine whether every group invite has been declined or whether enough participants remain connected. `onCallUpdated` performs those aggregate checks with Admin SDK and marks a ringing group call rejected after every callee declines, or ends an active call when its last eligible participant leaves. These server-side aggregate outcomes are asynchronous relative to the participant update.

Legacy call documents remain readable through `Call.fromMap()` fallback. Their existing array schema cannot safely use the new participant transition rules; allow active calls to finish before deploying the new Rules and client together.

## Emulator checks

Run `firebase emulators:exec --only firestore --project demo-collabtasks-rules "npm --prefix firestore-rules-tests test"` from the repository root. The test suite loads the checked-in `firestore.rules` and covers authenticated membership, forbidden writes, call transitions, and the two incoming-call query shapes.

## Index

`firestore.indexes.json` defines the composite index for `calleeIds array-contains` plus `status ==`. The same index serves both `ringing` and `active` incoming-call queries.
