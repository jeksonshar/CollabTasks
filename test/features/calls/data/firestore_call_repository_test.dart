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
  _StatefulDocumentSnapshot(this.documentData);

  final Map<String, dynamic> documentData;

  @override
  bool get exists => true;

  @override
  Map<String, dynamic> data() => documentData;
}

class _StatefulTransaction extends Fake implements Transaction {
  _StatefulTransaction(this.readData);

  Map<String, dynamic> readData;
  final updates = <Map<String, dynamic>>[];

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(DocumentReference<T> documentReference) async {
    return _StatefulDocumentSnapshot(readData) as DocumentSnapshot<T>;
  }

  @override
  Transaction update(DocumentReference documentReference, Map<Object, Object?> data) {
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
}
