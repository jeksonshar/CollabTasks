# Firestore rules for calls

## Data and identity assumptions

Call documents use the fields serialized by `Call.toMap()` and participant fields serialized by
`CallParticipant.toMap()`. Participants are stored in `participantsByUser`, a map keyed by participant identity. Emails
are trimmed and lowercased; Firebase UIDs are trimmed but remain case-sensitive. `Call.fromMap()` converts the keyed map
back to the domain list; it can still read legacy `participants` arrays, but new writes use only `participantsByUser`.
Rules match either the authenticated Firebase UID or lowercased Auth email. Incoming-call listeners query `calleeIds`
with `arrayContains` and `status` with equality for both `ringing` and `active`.

Call reads are allowed to the caller, a current callee, or a member of the call's `workingGroups/{groupId}` document.
The group membership check matches the authenticated UID against `participantUserIds` and the lowercased Auth email
against `participantEmails`. This permits a group chat member to query the group's call history by `groupId` and
`isGroup`, including calls they did not answer or left after joining; it does not grant access to calls in other groups.

The group history query uses the `calls` composite index on `groupId` and `isGroup` from `firestore.indexes.json`.
Deploy the updated Firestore Rules and indexes together with the client change.

The caller may start a call and cancel a ringing call. The caller or a connected participant in an active group call may
invite one participant at a time. Re-inviting a `left` or `declined` participant returns only that participant's keyed
record to `ringing`. A callee may accept or reject their own ringing record. This supports accepting invitations to an
active group call while preserving the call's active status and immutable call metadata. Any call member may end or
leave a call. Clients cannot delete call documents.

## Participant map and aggregate transitions

Rules compare `participantsByUser.diff()` and require exactly one changed key for participant transitions. The changed
key must match the authenticated user's UID or email, and that record's diff is restricted to the fields for the
transition. Invites use `lastInvitedParticipantId` to identify the single map key changed by the caller. Caller-only
creation still supplies the initial invited participant map; the caller cannot create a call on behalf of another
caller.

Rules cannot iterate the participant map to determine whether every group invite has been declined or whether enough
participants remain connected. `onCallUpdated` performs those aggregate checks with Admin SDK and marks a ringing group
call rejected after every callee declines, or ends an active call when its last eligible participant leaves. These
server-side aggregate outcomes are asynchronous relative to the participant update.

Heartbeat documents are stored at `calls/{callId}/heartbeats/{participantId}`. The Rules select `participantId` by
preferring the authenticated user's lowercased ID-token email claim when that key exists in `participantsByUser`,
otherwise by Firebase UID. `FirestoreCallRepository.updateParticipantHeartbeat` reads the email from the same token
claims, selects the matching raw participant-map key, and verifies that the selected record's `userId` equals its map
key and its status is `connected` before writing a server timestamp. It reads the call document and writes the heartbeat
as separate operations so a permission error identifies which operation was rejected. Error messages include only the
operation and Firebase error code, never the participant email or UID. The Rules allow only that authenticated
connected participant to create or refresh their own heartbeat document; do not choose the heartbeat path from a
decoded participant value or a potentially stale `User.email` when it may differ from the ID-token claim.

`connectedHeartbeatOwner()` checks parent-call existence with `exists(callPath)`. A value returned by `get(callPath)`
exposes its fields through `.data` and has no `.exists` property. Heartbeat creation and refresh remain restricted to an
authenticated connected participant whose selected email-or-UID key matches their participant record.

Legacy call documents remain readable through `Call.fromMap()` fallback. Their existing array schema cannot safely use
the new participant transition rules; allow active calls to finish before deploying the new Rules and client together.

## Emulator checks

Run
`firebase emulators:exec --only firestore --project demo-collabtasks-rules "npm --prefix firestore-rules-tests test"`
from the repository root. The test suite loads the checked-in `firestore.rules` and covers authenticated membership,
forbidden writes, call transitions, the two incoming-call query shapes, and heartbeat creation/refresh for email-keyed
and UID-keyed participants. It also verifies rejection of a connected member using the wrong alias and of a stranger.
The suite passed all 19 tests after the parent-call existence check was corrected.

## Index

`firestore.indexes.json` defines the composite index for `calleeIds array-contains` plus `status ==`. The same index
serves both `ringing` and `active` incoming-call queries.
