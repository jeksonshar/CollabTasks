const fs = require('node:fs');
const path = require('node:path');
const { after, before, beforeEach, describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
} = require('firebase/firestore');

const projectId = 'demo-collabtasks-rules';
const callId = 'call-rules-test';
let testEnv;

function callDocument(overrides = {}) {
  return {
    id: callId,
    callerId: 'caller@example.com',
    callerName: 'Caller',
    callerAvatarUrl: null,
    calleeIds: ['callee@example.com'],
    type: 'audio',
    status: 'ringing',
    isGroup: false,
    groupId: null,
    participantsByUser: {
      'caller@example.com': {
        userId: 'caller@example.com',
        displayName: 'Caller',
        avatarUrl: null,
        role: 'host',
        status: 'connected',
        joinedAtMillis: 1000,
      },
      'callee@example.com': {
        userId: 'callee@example.com',
        displayName: 'Callee',
        avatarUrl: null,
        role: 'participant',
        status: 'ringing',
        joinedAtMillis: null,
      },
    },
    createdAtMillis: 1000,
    startedAtMillis: null,
    endedAtMillis: null,
    ...overrides,
  };
}

function userDb(uid, email) {
  return testEnv.authenticatedContext(uid, { email }).firestore();
}

async function seedCall(overrides = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'calls', callId), callDocument(overrides));
  });
}

describe('Firestore /calls security rules', () => {
  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId,
      firestore: {
        host: '127.0.0.1',
        port: 8080,
        rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
      },
    });
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
    await seedCall();
  });

  after(async () => {
    await testEnv?.cleanup();
  });

  it('denies unauthenticated call reads and writes', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    const ref = doc(db, 'calls', callId);
    await assertFails(getDoc(ref));
    await assertFails(getDocs(collection(db, 'calls')));
    await assertFails(setDoc(doc(db, 'calls', 'unauth-call'), callDocument({ id: 'unauth-call' })));
    await assertFails(updateDoc(ref, { status: 'ended' }));
    await assertFails(deleteDoc(ref));
  });

  it('denies a stranger creating as another user or accessing another user call', async () => {
    const strangerDb = userDb('stranger-uid', 'stranger@example.com');
    await assertFails(
      setDoc(doc(strangerDb, 'calls', 'forged-call'), callDocument({
        id: 'forged-call',
        callerId: 'caller@example.com',
      })),
    );
    await assertFails(getDoc(doc(strangerDb, 'calls', callId)));
    await assertFails(updateDoc(doc(strangerDb, 'calls', callId), { status: 'ended' }));
    await assertFails(deleteDoc(doc(strangerDb, 'calls', callId)));
  });

  it('allows participants to query incoming calls and perform their call actions', async () => {
    const calleeDb = userDb('callee-uid', 'callee@example.com');
    const ringingQuery = query(
      collection(calleeDb, 'calls'),
      where('calleeIds', 'array-contains', 'callee@example.com'),
      where('status', '==', 'ringing'),
    );
    const ringing = await assertSucceeds(getDocs(ringingQuery));
    assert.equal(ringing.size, 1);
    await assertSucceeds(getDoc(doc(calleeDb, 'calls', callId)));

    const activeQuery = query(
      collection(calleeDb, 'calls'),
      where('calleeIds', 'array-contains', 'callee@example.com'),
      where('status', '==', 'active'),
    );
    await assertSucceeds(getDocs(activeQuery));

    const uidCall = callDocument({
      id: 'uid-call',
      calleeIds: ['callee-uid'],
      participantsByUser: {
        'caller@example.com': callDocument().participantsByUser['caller@example.com'],
        'callee-uid': {
          ...callDocument().participantsByUser['callee@example.com'],
          userId: 'callee-uid',
        },
      },
    });
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'calls', 'uid-call'), uidCall);
    });
    const uidQuery = query(
      collection(calleeDb, 'calls'),
      where('calleeIds', 'array-contains', 'callee-uid'),
      where('status', '==', 'ringing'),
    );
    const uidIncoming = await assertSucceeds(getDocs(uidQuery));
    assert.equal(uidIncoming.size, 1);
    await assertSucceeds(updateDoc(doc(calleeDb, 'calls', 'uid-call'), {
      status: 'active',
      startedAtMillis: 2000,
      participantsByUser: {
        'caller@example.com': uidCall.participantsByUser['caller@example.com'],
        'callee-uid': {
          ...uidCall.participantsByUser['callee-uid'],
          status: 'connected',
          joinedAtMillis: 2000,
        },
      },
    }));

    const accepted = callDocument({
      status: 'active',
      startedAtMillis: 2000,
      participantsByUser: {
        'caller@example.com': callDocument().participantsByUser['caller@example.com'],
        'callee@example.com': {
          ...callDocument().participantsByUser['callee@example.com'],
          status: 'connected', joinedAtMillis: 2000,
        },
      },
    });
    await assertSucceeds(setDoc(doc(calleeDb, 'calls', callId), accepted));
    await assertSucceeds(updateDoc(doc(calleeDb, 'calls', callId), {
      status: 'ended',
      endedAtMillis: 3000,
    }));
  });

  it('allows a caller to create only their own valid ringing call', async () => {
    const callerDb = userDb('caller-uid', 'caller@example.com');
    const newCall = callDocument({ id: 'new-call' });
    await assertSucceeds(setDoc(doc(callerDb, 'calls', 'new-call'), newCall));
  });

  it('allows a callee to reject and leave their call', async () => {
    const calleeDb = userDb('callee-uid', 'callee@example.com');
    const callRef = doc(calleeDb, 'calls', callId);
    const base = callDocument();
    await assertSucceeds(updateDoc(callRef, {
      status: 'rejected',
      endedAtMillis: 2500,
      participantsByUser: {
        ...base.participantsByUser,
        'callee@example.com': { ...base.participantsByUser['callee@example.com'], status: 'declined' },
      },
    }));

    await seedCall({ isGroup: true });
    await assertSucceeds(updateDoc(callRef, {
      calleeIds: [],
      participantsByUser: {
        ...base.participantsByUser,
        'callee@example.com': { ...base.participantsByUser['callee@example.com'], status: 'left' },
      },
    }));
  });

  it('keeps a group call ringing after one recipient declines and reserves terminal rejection for the server', async () => {
    const base = callDocument();
    const groupParticipants = {
      ...base.participantsByUser,
      'other@example.com': {
        userId: 'other@example.com',
        displayName: 'Other',
        avatarUrl: null,
        role: 'participant',
        status: 'ringing',
        joinedAtMillis: null,
      },
    };
    await seedCall({
      isGroup: true,
      calleeIds: ['callee@example.com', 'other@example.com'],
      participantsByUser: groupParticipants,
    });

    const calleeDb = userDb('callee-uid', 'callee@example.com');
    await assertSucceeds(updateDoc(doc(calleeDb, 'calls', callId), {
      participantsByUser: {
        ...groupParticipants,
        'callee@example.com': {
          ...groupParticipants['callee@example.com'],
          status: 'declined',
        },
      },
    }));
    await assertFails(updateDoc(doc(calleeDb, 'calls', callId), {
      status: 'rejected',
      endedAtMillis: 4000,
    }));
  });

  it('allows active group invite acceptance and rejects invalid or cross-participant updates', async () => {
    const base = callDocument();
    const calleeDb = userDb('callee-uid', 'callee@example.com');
    const callRef = doc(calleeDb, 'calls', callId);
    const accepted = {
      ...base.participantsByUser,
      'callee@example.com': {
        ...base.participantsByUser['callee@example.com'],
        status: 'connected',
        joinedAtMillis: 3000,
      },
    };

    await seedCall({ isGroup: true, status: 'active', startedAtMillis: 2000 });
    await assertSucceeds(updateDoc(callRef, { participantsByUser: accepted }));

    await seedCall({ isGroup: true, status: 'active', startedAtMillis: 2000 });
    await assertFails(updateDoc(callRef, {
      participantsByUser: accepted,
      startedAtMillis: 4000,
    }));
    await assertFails(updateDoc(callRef, {
      participantsByUser: accepted,
      calleeIds: ['callee@example.com', 'other@example.com'],
    }));
    await assertFails(updateDoc(callRef, {
      participantsByUser: {
        ...accepted,
        'callee@example.com': {
          ...accepted['callee@example.com'], displayName: 'Changed by accept',
        },
      },
    }));
    await assertFails(updateDoc(callRef, {
      participantsByUser: {
        ...accepted,
        'callee@example.com': {
          ...accepted['callee@example.com'], userId: 'other@example.com',
        },
      },
    }));

    await seedCall({ isGroup: false, status: 'active', startedAtMillis: 2000 });
    await assertFails(updateDoc(callRef, { participantsByUser: accepted }));

    await seedCall({
      isGroup: true,
      status: 'active',
      startedAtMillis: 2000,
      participantsByUser: {
        ...base.participantsByUser,
        'callee@example.com': {
          ...base.participantsByUser['callee@example.com'], status: 'connected', joinedAtMillis: 2500,
        },
      },
    });
    await assertFails(updateDoc(callRef, { participantsByUser: accepted }));

    await seedCall({
      isGroup: true, status: 'ended', startedAtMillis: 2000, endedAtMillis: 2500,
    });
    await assertFails(updateDoc(callRef, { participantsByUser: accepted }));

    await seedCall({ isGroup: true, status: 'active', startedAtMillis: 2000 });
    await assertFails(updateDoc(
      doc(userDb('stranger-uid', 'stranger@example.com'), 'calls', callId),
      { participantsByUser: accepted },
    ));

    await seedCall({ isGroup: true, status: 'active', startedAtMillis: 2000 });
    await assertFails(updateDoc(callRef, {
      participantsByUser: {
        ...accepted,
        'caller@example.com': {
          ...base.participantsByUser['caller@example.com'], displayName: 'Spoofed caller',
        },
      },
    }));
  });

  it('denies caller spoofing, broad callee list edits, arbitrary statuses, and deletion', async () => {
    const callerDb = userDb('caller-uid', 'caller@example.com');
    const calleeDb = userDb('callee-uid', 'callee@example.com');
    const callerRef = doc(callerDb, 'calls', callId);
    const calleeRef = doc(calleeDb, 'calls', callId);
    const participantsByUser = callDocument().participantsByUser;

    await assertFails(updateDoc(callerRef, { callerId: 'attacker@example.com' }));
    await assertFails(updateDoc(callerRef, {
      calleeIds: ['attacker@example.com', 'other@example.com'],
      participantsByUser,
    }));
    await assertFails(updateDoc(callerRef, { status: 'busy' }));
    await assertFails(updateDoc(calleeRef, { status: 'cancelled' }));
    await assertFails(deleteDoc(callerRef));
  });

  it('allows caller cancellation and a single invite, but prevents callee list replacement', async () => {
    const callerDb = userDb('caller-uid', 'caller@example.com');
    const callerRef = doc(callerDb, 'calls', callId);
    await assertFails(updateDoc(callerRef, {
      status: 'cancelled',
      endedAtMillis: 4000,
      participantsByUser: {
        ...callDocument().participantsByUser,
        'callee@example.com': {
          ...callDocument().participantsByUser['callee@example.com'], status: 'connected',
        },
      },
    }));
    await assertSucceeds(updateDoc(callerRef, {
      status: 'cancelled',
      endedAtMillis: 4000,
    }));

    await seedCall({ isGroup: true });
    await assertSucceeds(updateDoc(callerRef, {
      calleeIds: ['callee@example.com', 'new@example.com'],
      participantsByUser: {
        ...callDocument().participantsByUser,
        'new@example.com': {
          userId: 'new@example.com', displayName: 'New', avatarUrl: null,
          role: 'participant', status: 'ringing', joinedAtMillis: null,
        },
      },
      lastInvitedParticipantId: 'new@example.com',
    }));
    await assertFails(updateDoc(callerRef, {
      calleeIds: ['attacker@example.com'],
      participantsByUser: callDocument().participantsByUser,
    }));
  });

  it('allows callers to re-invite participants whose status is left or declined', async () => {
    const callerDb = userDb('caller-uid', 'caller@example.com');
    const callerRef = doc(callerDb, 'calls', callId);
    const base = callDocument();

    for (const previousStatus of ['left', 'declined']) {
      const calleeIds = previousStatus === 'left' ? [] : ['callee@example.com'];
      await seedCall({
        isGroup: true,
        status: 'active',
        startedAtMillis: 2000,
        calleeIds,
        participantsByUser: {
          ...base.participantsByUser,
          'callee@example.com': {
            ...base.participantsByUser['callee@example.com'],
            status: previousStatus,
            joinedAtMillis: previousStatus === 'left' ? 1500 : null,
          },
        },
      });

      await assertSucceeds(updateDoc(callerRef, {
        calleeIds: ['callee@example.com'],
        participantsByUser: {
          ...base.participantsByUser,
          'callee@example.com': {
            ...base.participantsByUser['callee@example.com'],
            status: 'ringing',
            joinedAtMillis: null,
          },
        },
        lastInvitedParticipantId: 'callee@example.com',
      }));

      const calleeRef = doc(userDb('callee-uid', 'callee@example.com'), 'calls', callId);
      const acceptedParticipants = {
        ...base.participantsByUser,
        'callee@example.com': {
          ...base.participantsByUser['callee@example.com'],
          status: 'connected',
          joinedAtMillis: 3000,
        },
      };
      await assertSucceeds(updateDoc(calleeRef, {
        participantsByUser: acceptedParticipants,
      }));
    }
  });

  it('allows an already connected group member to re-invite a participant', async () => {
    const base = callDocument();
    const participantsByUser = {
      ...base.participantsByUser,
      'callee@example.com': {
        ...base.participantsByUser['callee@example.com'],
        status: 'left',
      },
      'member@example.com': {
        userId: 'member@example.com',
        displayName: 'Connected member',
        avatarUrl: null,
        role: 'participant',
        status: 'connected',
        joinedAtMillis: 2500,
      },
    };
    await seedCall({
      isGroup: true,
      status: 'active',
      startedAtMillis: 2000,
      calleeIds: ['member@example.com'],
      participantsByUser,
    });

    const memberDb = userDb('member-uid', 'member@example.com');
    await assertSucceeds(updateDoc(doc(memberDb, 'calls', callId), {
      calleeIds: ['member@example.com', 'callee@example.com'],
      participantsByUser: {
        ...participantsByUser,
        'callee@example.com': {
          ...participantsByUser['callee@example.com'],
          status: 'ringing',
        },
      },
      lastInvitedParticipantId: 'callee@example.com',
    }));

    const ringingParticipant = userDb('callee-uid', 'callee@example.com');
    await assertSucceeds(updateDoc(doc(ringingParticipant, 'calls', callId), {
      participantsByUser: {
        ...participantsByUser,
        'callee@example.com': {
          ...participantsByUser['callee@example.com'],
          status: 'connected',
          joinedAtMillis: 3000,
        },
      },
    }));
  });

  it('does not allow a non-connected invitee to invite another user', async () => {
    const calleeDb = userDb('callee-uid', 'callee@example.com');
    await seedCall({ isGroup: true, status: 'active', startedAtMillis: 2000 });

    await assertFails(updateDoc(doc(calleeDb, 'calls', callId), {
      calleeIds: ['callee@example.com', 'other@example.com'],
      participantsByUser: {
        ...callDocument().participantsByUser,
        'other@example.com': {
          userId: 'other@example.com',
          displayName: 'Other',
          avatarUrl: null,
          role: 'participant',
          status: 'ringing',
          joinedAtMillis: null,
        },
      },
      lastInvitedParticipantId: 'other@example.com',
    }));
  });

  it('supports leave, invite by another connected member, and re-accept as one flow', async () => {
    const base = callDocument();
    const participantsByUser = {
      ...base.participantsByUser,
      'callee@example.com': {
        ...base.participantsByUser['callee@example.com'],
        status: 'connected',
        joinedAtMillis: 2200,
      },
      'member@example.com': {
        userId: 'member@example.com',
        displayName: 'Connected member',
        avatarUrl: null,
        role: 'participant',
        status: 'connected',
        joinedAtMillis: 2300,
      },
    };
    await seedCall({
      isGroup: true,
      status: 'active',
      startedAtMillis: 2000,
      calleeIds: ['callee@example.com', 'member@example.com'],
      participantsByUser,
    });

    const calleeDb = userDb('callee-uid', 'callee@example.com');
    await assertSucceeds(updateDoc(doc(calleeDb, 'calls', callId), {
      calleeIds: ['member@example.com'],
      participantsByUser: {
        ...participantsByUser,
        'callee@example.com': {
          ...participantsByUser['callee@example.com'],
          status: 'left',
        },
      },
    }));

    const memberDb = userDb('member-uid', 'member@example.com');
    await assertSucceeds(updateDoc(doc(memberDb, 'calls', callId), {
      calleeIds: ['member@example.com', 'callee@example.com'],
      participantsByUser: {
        ...participantsByUser,
        'callee@example.com': {
          ...participantsByUser['callee@example.com'],
          status: 'ringing',
          joinedAtMillis: null,
        },
      },
      lastInvitedParticipantId: 'callee@example.com',
    }));

    await assertSucceeds(updateDoc(doc(calleeDb, 'calls', callId), {
      participantsByUser: {
        ...participantsByUser,
        'callee@example.com': {
          ...participantsByUser['callee@example.com'],
          status: 'connected',
          joinedAtMillis: 3000,
        },
      },
    }));
  });
});
