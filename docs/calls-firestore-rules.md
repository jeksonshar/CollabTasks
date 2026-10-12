# Firestore rules for calls

## Data and identity assumptions

Call documents use the fields serialized by `Call.toMap()` and participant fields serialized by `CallParticipant.toMap()`. Call identity values are normalized to lowercase in `FirestoreCallRepository`; rules match either the authenticated Firebase UID or the lowercased Auth email. Incoming-call listeners query `calleeIds` with `arrayContains` and `status` with equality for both `ringing` and `active`.

The caller may start a call, cancel a ringing call, and invite one participant at a time. A callee may accept or reject. Any call member may end or leave a call. Clients cannot delete call documents.

## Rules language limitation

Rules restrict each operation to its required top-level fields and state transitions. The existing repository rewrites `participants` as one list, and Firestore Rules cannot iterate that arbitrary list to prove that only the authenticated participant's map changed. Therefore accept, reject, leave, and invite updates still permit a malicious member to alter another map in the same `participants` list write. Fully enforcing that invariant needs a keyed participant map/subcollection or a trusted callable backend, plus a repository migration; it cannot be safely achieved by Security Rules alone with the current list schema.

## Emulator checks

Run `firebase emulators:exec --only firestore --project demo-collabtasks-rules "npm --prefix firestore-rules-tests test"` from the repository root. The test suite loads the checked-in `firestore.rules` and covers authenticated membership, forbidden writes, call transitions, and the two incoming-call query shapes.

## Index

`firestore.indexes.json` defines the composite index for `calleeIds array-contains` plus `status ==`. The same index serves both `ringing` and `active` incoming-call queries.
