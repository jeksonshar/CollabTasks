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
    participants: [
      {
        userId: 'caller@example.com',
        displayName: 'Caller',
        avatarUrl: null,
        role: 'host',
        status: 'connected',
        joinedAtMillis: 1000,
      },
      {
        userId: 'callee@example.com',
        displayName: 'Callee',
        avatarUrl: null,
        role: 'participant',
        status: 'ringing',
        joinedAtMillis: null,
      },
    ],
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

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const uidCall = callDocument({
        id: 'uid-call',
        calleeIds: ['callee-uid'],
        participants: [
          callDocument().participants[0],
          { ...callDocument().participants[1], userId: 'callee-uid' },
        ],
      });
      await setDoc(doc(context.firestore(), 'calls', 'uid-call'), uidCall);
    });
    const uidQuery = query(
      collection(calleeDb, 'calls'),
      where('calleeIds', 'array-contains', 'callee-uid'),
      where('status', '==', 'ringing'),
    );
    const uidIncoming = await assertSucceeds(getDocs(uidQuery));
    assert.equal(uidIncoming.size, 1);

    const accepted = callDocument({
      status: 'active',
      startedAtMillis: 2000,
      participants: [
        callDocument().participants[0],
        { ...callDocument().participants[1], status: 'connected', joinedAtMillis: 2000 },
      ],
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
    await assertSucceeds(setDoc(callRef, callDocument({
      status: 'rejected',
      endedAtMillis: 2500,
      participants: [base.participants[0], { ...base.participants[1], status: 'declined' }],
    })));

    await seedCall();
    await assertSucceeds(setDoc(callRef, callDocument({
      status: 'ended',
      endedAtMillis: 3000,
      calleeIds: [],
      participants: [base.participants[0], { ...base.participants[1], status: 'left' }],
    })));
  });

  it('denies caller spoofing, broad callee list edits, arbitrary statuses, and deletion', async () => {
    const callerDb = userDb('caller-uid', 'caller@example.com');
    const calleeDb = userDb('callee-uid', 'callee@example.com');
    const callerRef = doc(callerDb, 'calls', callId);
    const calleeRef = doc(calleeDb, 'calls', callId);

    await assertFails(updateDoc(callerRef, { callerId: 'attacker@example.com' }));
    await assertFails(updateDoc(callerRef, {
      calleeIds: ['attacker@example.com', 'other@example.com'],
      participants: callDocument().participants,
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
      participants: [
        { ...callDocument().participants[0], displayName: 'Changed during cancel' },
        callDocument().participants[1],
      ],
    }));
    await assertSucceeds(updateDoc(callerRef, {
      status: 'cancelled',
      endedAtMillis: 4000,
    }));

    await seedCall();
    await assertSucceeds(updateDoc(callerRef, {
      calleeIds: ['callee@example.com', 'new@example.com'],
      participants: [
        ...callDocument().participants,
        {
          userId: 'new@example.com', displayName: 'New', avatarUrl: null,
          role: 'participant', status: 'ringing', joinedAtMillis: null,
        },
      ],
    }));
    await assertFails(updateDoc(callerRef, {
      calleeIds: ['attacker@example.com'],
      participants: callDocument().participants,
    }));
  });
});
