// Mocktail fakes are used for Firestore interfaces whose FlutterFire types are sealed.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collab_tasks/features/calls/data/repositories/firestore_call_repository.dart';
import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/models/call_participant.dart';
import 'package:collab_tasks/features/calls/domain/models/call_status.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCollection extends Mock implements CollectionReference<Map<String, dynamic>> {}

class _MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}

class _MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _StatefulDocumentSnapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _StatefulDocumentSnapshot(this.documentData, {this.documentExists = true});

  final Map<String, dynamic> documentData;
  final bool documentExists;

  @override
  bool get exists => documentExists;

  @override
  Map<String, dynamic> data() => documentData;
}

class _StatefulTransaction extends Fake implements Transaction {
  _StatefulTransaction(this.readData);

  Map<String, dynamic> readData;
  bool exists = true;
  Object? readError;
  Object? updateError;
  final updates = <Map<String, dynamic>>[];

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(DocumentReference<T> documentReference) async {
    if (readError != null) throw readError!;
    return _StatefulDocumentSnapshot(readData, documentExists: exists) as DocumentSnapshot<T>;
  }

  @override
  Transaction update(DocumentReference documentReference, Map<Object, Object?> data) {
    if (updateError != null) throw updateError!;
    final update = Map<String, dynamic>.fromEntries(
      data.entries.map((entry) => MapEntry(entry.key.toString(), entry.value)),
    );
    updates.add(update);
    readData = {...readData, ...update};
    return this;
  }
}

class _StatefulFirestore extends Fake implements FirebaseFirestore {
  _StatefulFirestore(this.collectionReference, this.transaction);

  final CollectionReference<Map<String, dynamic>> collectionReference;
  final Transaction transaction;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      collectionReference;

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) => transactionHandler(transaction);
}

void main() {
  const callerId = 'caller@example.com';
  const calleeId = 'callee@example.com';
  const callId = 'call-firestore-test';
  final createdAt = DateTime.fromMillisecondsSinceEpoch(1000);

  late FirebaseFirestore firestore;
  late _MockCollection collection;
  late _MockDocumentReference documentReference;
  late _MockFirebaseAuth auth;
  late _MockUser user;
  late _StatefulTransaction transaction;
  late FirestoreCallRepository repository;
  late Map<String, dynamic> storedData;

  Map<String, dynamic> initialCall({
    CallStatus status = CallStatus.ringing,
    bool isGroup = true,
    CallParticipantStatus calleeStatus = CallParticipantStatus.ringing,
    DateTime? calleeJoinedAt,
    List<String>? calleeIds,
  }) {
    return Call(
      id: callId,
      callerId: callerId,
      callerName: 'Caller',
      calleeIds: calleeIds ?? [calleeId],
      type: CallType.video,
      status: status,
      isGroup: isGroup,
      startedAt: status == CallStatus.active ? DateTime.fromMillisecondsSinceEpoch(2000) : null,
      participants: [
        CallParticipant(
          userId: callerId,
          displayName: 'Caller',
          role: CallParticipantRole.host,
          status: CallParticipantStatus.connected,
          joinedAt: createdAt,
        ),
        CallParticipant(
          userId: calleeId,
          displayName: 'Callee',
          status: calleeStatus,
          joinedAt:
              calleeJoinedAt ??
              (calleeStatus == CallParticipantStatus.connected
                  ? DateTime.fromMillisecondsSinceEpoch(1500)
                  : null),
        ),
      ],
      createdAt: createdAt,
    ).toMap();
  }

  setUp(() {
    collection = _MockCollection();
    documentReference = _MockDocumentReference();
    auth = _MockFirebaseAuth();
    user = _MockUser();
    storedData = initialCall();
    transaction = _StatefulTransaction(storedData);
    firestore = _StatefulFirestore(collection, transaction);

    when(() => collection.doc(callId)).thenReturn(documentReference);
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('callee-uid');
    when(() => user.email).thenReturn(calleeId);
    when(() => documentReference.get()).thenAnswer((_) async {
      final snapshot = _MockDocumentSnapshot();
      when(() => snapshot.exists).thenReturn(true);
      when(() => snapshot.data()).thenReturn(storedData);
      return snapshot;
    });
    repository = FirestoreCallRepository(firestore: firestore, auth: auth);
  });

  test('reads participants from the keyed Firestore map', () async {
    final call = await repository.getCallById(callId);

    expect(
      call?.participants.map((participant) => participant.userId),
      containsAll([callerId, calleeId]),
    );
    expect(
      call?.participants.firstWhere((participant) => participant.userId == calleeId).status,
      CallParticipantStatus.ringing,
    );
  });

  test('accepts a ringing participant in an active group without changing call metadata', () async {
    storedData = initialCall(status: CallStatus.active);
    transaction.readData = storedData;

    await repository.acceptCall(callId: callId, userId: 'callee-uid');

    final updated = Call.fromMap(transaction.readData);
    expect(updated.status, CallStatus.active);
    expect(updated.startedAt, DateTime.fromMillisecondsSinceEpoch(2000));
    expect(updated.callerId, callerId);
    expect(updated.calleeIds, [calleeId]);
    expect(
      updated.participants.firstWhere((participant) => participant.userId == calleeId).status,
      CallParticipantStatus.connected,
    );
    expect(transaction.updates.single['participantsByUser'], isA<Map<String, dynamic>>());
  });

  test('accepts an ordinary ringing call and sets its start time', () async {
    storedData = initialCall(isGroup: false);
    transaction.readData = storedData;

    await repository.acceptCall(callId: callId, userId: calleeId);

    final updated = Call.fromMap(transaction.readData);
    expect(updated.status, CallStatus.active);
    expect(updated.startedAt, isNotNull);
    expect(
      updated.participants.firstWhere((participant) => participant.userId == calleeId).status,
      CallParticipantStatus.connected,
    );
  });

  test('missing calls are reported for accept, reject, leave, and invite', () async {
    transaction.exists = false;

    await expectLater(
      repository.acceptCall(callId: callId, userId: calleeId),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      repository.rejectCall(callId: callId, userId: calleeId),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      repository.leaveCall(callId: callId, userId: calleeId),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      repository.inviteParticipant(
        callId: callId,
        userId: 'other@example.com',
        displayName: 'Other',
      ),
      throwsA(isA<StateError>()),
    );
    expect(transaction.updates, isEmpty);
  });

  test('rejects invalid actors and terminal call transitions without writes', () async {
    await expectLater(
      repository.acceptCall(callId: callId, userId: 'other@example.com'),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      repository.rejectCall(callId: callId, userId: 'other@example.com'),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      repository.leaveCall(callId: callId, userId: 'other@example.com'),
      throwsA(isA<StateError>()),
    );

    storedData = initialCall(status: CallStatus.ended);
    transaction.readData = storedData;
    await expectLater(
      repository.acceptCall(callId: callId, userId: calleeId),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      repository.rejectCall(callId: callId, userId: calleeId),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      repository.leaveCall(callId: callId, userId: calleeId),
      throwsA(isA<StateError>()),
    );
    expect(transaction.updates, isEmpty);
  });

  test('declining one group participant leaves the call active', () async {
    storedData = initialCall(status: CallStatus.active, isGroup: true);
    transaction.readData = storedData;

    await repository.rejectCall(callId: callId, userId: calleeId);

    final updated = Call.fromMap(transaction.readData);
    expect(updated.status, CallStatus.active);
    expect(updated.endedAt, isNull);
    expect(
      updated.participants.firstWhere((participant) => participant.userId == calleeId).status,
      CallParticipantStatus.declined,
    );
    expect(
      updated.participants.firstWhere((participant) => participant.userId == callerId).status,
      CallParticipantStatus.connected,
    );
  });

  test(
    're-invites a left participant by updating only that keyed record and callee list',
    () async {
      storedData = initialCall(
        status: CallStatus.active,
        calleeStatus: CallParticipantStatus.left,
        calleeJoinedAt: DateTime.fromMillisecondsSinceEpoch(1500),
        calleeIds: const [],
      );
      transaction.readData = storedData;
      when(() => user.uid).thenReturn('caller-uid');
      when(() => user.email).thenReturn(callerId);

      await repository.inviteParticipant(callId: callId, userId: calleeId, displayName: 'Callee');

      expect(
        transaction.updates.last.keys,
        containsAll(['calleeIds', 'participantsByUser', 'lastInvitedParticipantId']),
      );
      expect(transaction.updates.last.keys, isNot(contains('endedAtMillis')));
      expect(transaction.updates.last.keys, isNot(contains('status')));

      final updated = Call.fromMap(transaction.readData);
      expect(updated.status, CallStatus.active);
      expect(updated.calleeIds, [calleeId]);
      expect(
        updated.participants.firstWhere((participant) => participant.userId == calleeId).status,
        CallParticipantStatus.ringing,
      );
      expect(
        updated.participants.firstWhere((participant) => participant.userId == calleeId).joinedAt,
        isNull,
      );
      expect(transaction.readData['lastInvitedParticipantId'], calleeId);

      when(() => user.uid).thenReturn('callee-uid');
      when(() => user.email).thenReturn(calleeId);
      await repository.acceptCall(callId: callId, userId: calleeId);
      expect(
        transaction.readData['lastInvitedParticipantId'],
        calleeId,
        reason: 'accept must preserve the Rules invite target marker',
      );
      expect(
        Call.fromMap(
          transaction.readData,
        ).participants.firstWhere((participant) => participant.userId == calleeId).status,
        CallParticipantStatus.connected,
      );
    },
  );

  test('allows a connected group member other than the caller to re-invite', () async {
    const memberId = 'member@example.com';
    final activeCall = Call.fromMap(
      initialCall(
        status: CallStatus.active,
        calleeStatus: CallParticipantStatus.left,
        calleeIds: const [memberId],
      ),
    );
    storedData = activeCall
        .copyWith(
          participants: [
            ...activeCall.participants,
            CallParticipant(
              userId: memberId,
              displayName: 'Connected member',
              status: CallParticipantStatus.connected,
              joinedAt: DateTime.fromMillisecondsSinceEpoch(2500),
            ),
          ],
        )
        .toMap();
    transaction.readData = storedData;
    when(() => user.uid).thenReturn('member-uid');
    when(() => user.email).thenReturn(memberId);

    await repository.inviteParticipant(callId: callId, userId: calleeId, displayName: 'Callee');

    final updated = Call.fromMap(transaction.readData);
    expect(updated.calleeIds, containsAll([memberId, calleeId]));
    expect(
      updated.participants.firstWhere((participant) => participant.userId == calleeId).status,
      CallParticipantStatus.ringing,
    );
  });

  test('leaves the group and removes the callee before the caller re-invites them', () async {
    storedData = initialCall(
      status: CallStatus.active,
      calleeStatus: CallParticipantStatus.connected,
    );
    transaction.readData = storedData;

    await repository.leaveCall(callId: callId, userId: calleeId);

    var updated = Call.fromMap(transaction.readData);
    expect(updated.calleeIds, isEmpty);
    expect(
      updated.participants.firstWhere((participant) => participant.userId == calleeId).status,
      CallParticipantStatus.left,
    );
    expect(
      updated.participants.firstWhere((participant) => participant.userId == calleeId).joinedAt,
      DateTime.fromMillisecondsSinceEpoch(1500),
    );

    when(() => user.uid).thenReturn('caller-uid');
    when(() => user.email).thenReturn(callerId);
    await repository.inviteParticipant(callId: callId, userId: calleeId, displayName: 'Callee');

    updated = Call.fromMap(transaction.readData);
    expect(updated.calleeIds, [calleeId]);
    expect(
      updated.participants.firstWhere((participant) => participant.userId == calleeId).status,
      CallParticipantStatus.ringing,
    );
    expect(
      updated.participants.firstWhere((participant) => participant.userId == calleeId).joinedAt,
      isNull,
    );
  });

  test('caller leave preserves calleeIds and does not end or timestamp the call', () async {
    storedData = initialCall(
      status: CallStatus.active,
      calleeStatus: CallParticipantStatus.connected,
    );
    transaction.readData = storedData;
    when(() => user.uid).thenReturn('caller-uid');
    when(() => user.email).thenReturn(callerId);

    await repository.leaveCall(callId: callId, userId: callerId);

    expect(transaction.updates.single.keys, containsAll(['calleeIds', 'participantsByUser']));
    expect(transaction.updates.single.keys, isNot(contains('endedAtMillis')));
    expect(transaction.updates.single.keys, isNot(contains('status')));

    final updated = Call.fromMap(transaction.readData);
    expect(updated.calleeIds, [calleeId]);
    expect(updated.status, CallStatus.active);
    expect(updated.endedAt, isNull);
    expect(
      updated.participants.firstWhere((participant) => participant.userId == callerId).status,
      CallParticipantStatus.left,
    );
  });

  test('cancelCall and endCall enforce caller, member, and status rules', () async {
    when(() => user.uid).thenReturn('caller-uid');
    when(() => user.email).thenReturn(callerId);
    await repository.cancelCall(callId);
    expect(transaction.updates.single['status'], CallStatus.cancelled.name);
    expect(transaction.updates.single.keys, containsAll(['status', 'endedAtMillis']));

    transaction.updates.clear();
    storedData = initialCall(status: CallStatus.active);
    transaction.readData = storedData;
    await expectLater(repository.cancelCall(callId), throwsA(isA<StateError>()));
    expect(transaction.updates, isEmpty);

    when(() => user.uid).thenReturn('callee-uid');
    when(() => user.email).thenReturn(calleeId);
    await expectLater(repository.cancelCall(callId), throwsA(isA<StateError>()));
    expect(transaction.updates, isEmpty);

    await repository.endCall(callId);
    expect(transaction.updates.single['status'], CallStatus.ended.name);

    transaction.updates.clear();
    when(() => user.uid).thenReturn('outsider-uid');
    when(() => user.email).thenReturn('outsider@example.com');
    await expectLater(repository.endCall(callId), throwsA(isA<StateError>()));
    expect(transaction.updates, isEmpty);

    storedData = initialCall(status: CallStatus.ended);
    transaction.readData = storedData;
    when(() => user.uid).thenReturn('caller-uid');
    when(() => user.email).thenReturn(callerId);
    await expectLater(repository.endCall(callId), throwsA(isA<StateError>()));
    expect(transaction.updates, isEmpty);
  });

  test('Firestore transaction read and write errors propagate to the caller', () async {
    final readFailure = FirebaseException(plugin: 'cloud_firestore', message: 'read failed');
    transaction.readError = readFailure;
    await expectLater(
      repository.acceptCall(callId: callId, userId: calleeId),
      throwsA(same(readFailure)),
    );

    transaction.readError = null;
    when(() => user.uid).thenReturn('caller-uid');
    when(() => user.email).thenReturn(callerId);
    final writeFailure = FirebaseException(plugin: 'cloud_firestore', message: 'write failed');
    transaction.updateError = writeFailure;
    await expectLater(repository.cancelCall(callId), throwsA(same(writeFailure)));
    await expectLater(repository.endCall(callId), throwsA(same(writeFailure)));
  });
}
