// Mocktail fakes are used for Firestore interfaces whose FlutterFire types are sealed.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collab_tasks/features/calls/data/remote/agora/agora_uid_mapper.dart';
import 'package:collab_tasks/features/calls/data/repositories/firestore_call_repository.dart';
import 'package:collab_tasks/features/calls/data/repositories/in_memory_call_repository.dart';
import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/models/call_participant.dart';
import 'package:collab_tasks/features/calls/domain/models/call_status.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCollection extends Mock implements CollectionReference<Map<String, dynamic>> {}

class _MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}

class _MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _HistoryQuery extends Fake implements Query<Map<String, dynamic>> {
  _HistoryQuery(this.documents);

  final List<MapEntry<String, Map<String, dynamic>>> documents;
  final orderByFields = <({Object field, bool descending})>[];
  List<Object?>? cursorValues;
  int? resultLimit;

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) => this;

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) {
    orderByFields.add((field: field, descending: descending));
    return this;
  }

  @override
  Query<Map<String, dynamic>> startAfter(Iterable<Object?> values) {
    cursorValues = values.toList();
    return this;
  }

  @override
  Query<Map<String, dynamic>> limit(int limit) {
    resultLimit = limit;
    return this;
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final sorted = List<MapEntry<String, Map<String, dynamic>>>.from(documents)
      ..sort((a, b) {
        final timestampA = (a.value['createdAtMillis'] as num).toInt();
        final timestampB = (b.value['createdAtMillis'] as num).toInt();
        final byTimestamp = timestampB.compareTo(timestampA);
        return byTimestamp != 0 ? byTimestamp : b.key.compareTo(a.key);
      });
    final after = cursorValues;
    final afterCursor = after == null
        ? sorted
        : sorted.where((entry) {
            final timestamp = (entry.value['createdAtMillis'] as num).toInt();
            final cursorTimestamp = after[0] as int;
            final cursorId = after[1] as String;
            return timestamp < cursorTimestamp ||
                (timestamp == cursorTimestamp && entry.key.compareTo(cursorId) < 0);
          }).toList();
    return _HistoryQuerySnapshot(
      resultLimit == null ? afterCursor : afterCursor.take(resultLimit!).toList(),
    );
  }
}

class _HistoryQuerySnapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  _HistoryQuerySnapshot(this.documents);

  final List<MapEntry<String, Map<String, dynamic>>> documents;

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs =>
      documents.map((entry) => _HistoryDocumentSnapshot(entry.key, entry.value)).toList();
}

class _HistoryDocumentSnapshot extends Fake implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _HistoryDocumentSnapshot(this.id, this.documentData);

  @override
  final String id;
  final Map<String, dynamic> documentData;

  @override
  Map<String, dynamic> data() => documentData;
}

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
  late AgoraUidMapper uidMapper;
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

  Call historyCall({
    required String id,
    required String callerId,
    required List<String> calleeIds,
    DateTime? createdAt,
    bool isGroup = false,
    String? groupId,
  }) => Call(
    id: id,
    callerId: callerId,
    callerName: 'History caller',
    calleeIds: calleeIds,
    type: CallType.audio,
    status: CallStatus.ended,
    isGroup: isGroup,
    groupId: groupId,
    createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(1000),
  );

  setUp(() {
    collection = _MockCollection();
    documentReference = _MockDocumentReference();
    auth = _MockFirebaseAuth();
    user = _MockUser();
    uidMapper = AgoraUidMapper();
    storedData = initialCall();
    transaction = _StatefulTransaction(storedData);
    firestore = _StatefulFirestore(collection, transaction);

    when(() => collection.doc(callId)).thenReturn(documentReference);
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('callee-uid');
    when(() => user.email).thenReturn(calleeId);
    when(() => user.getIdToken()).thenAnswer((_) async => 'firebase-id-token');
    when(() => documentReference.get()).thenAnswer((_) async {
      final snapshot = _MockDocumentSnapshot();
      when(() => snapshot.exists).thenReturn(true);
      when(() => snapshot.data()).thenReturn(storedData);
      return snapshot;
    });
    repository = FirestoreCallRepository(firestore: firestore, auth: auth, uidMapper: uidMapper);
  });

  test(
    'Direct history pages query authenticated aliases, filter the peer, and deduplicate overlaps',
    () async {
      final queryFilters = <({String field, Object? isEqualTo, Object? arrayContains})>[];
      final historyQueries = <_HistoryQuery>[];
      final matchingCall = historyCall(
        id: 'outgoing-match',
        callerId: 'callee-uid',
        calleeIds: const ['peer@example.com'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(3000),
      );
      final differentPeerCall = historyCall(
        id: 'outgoing-other-peer',
        callerId: 'callee-uid',
        calleeIds: const ['other@example.com'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(2500),
      );
      final aliasDuplicate = historyCall(
        id: 'incoming-alias-duplicate',
        callerId: 'peer@example.com',
        calleeIds: const ['callee-uid', 'callee@example.com'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(2000),
      );
      final olderCall = historyCall(
        id: 'incoming-older',
        callerId: 'peer@example.com',
        calleeIds: const ['callee-uid', 'callee@example.com'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
      );

      when(
        () => collection.where(
          any(),
          isEqualTo: any(named: 'isEqualTo'),
          arrayContains: any(named: 'arrayContains'),
        ),
      ).thenAnswer((invocation) {
        final field = invocation.positionalArguments.single as String;
        final isEqualTo = invocation.namedArguments[#isEqualTo];
        final arrayContains = invocation.namedArguments[#arrayContains];
        queryFilters.add((field: field, isEqualTo: isEqualTo, arrayContains: arrayContains));

        final List<MapEntry<String, Map<String, dynamic>>> documents = switch ((
          field,
          isEqualTo,
          arrayContains,
        )) {
          ('callerId', 'callee-uid', null) => [
            MapEntry(matchingCall.id, matchingCall.toMap()),
            MapEntry(differentPeerCall.id, differentPeerCall.toMap()),
          ],
          ('calleeIds', null, 'callee-uid') => [
            MapEntry(aliasDuplicate.id, aliasDuplicate.toMap()),
            MapEntry(olderCall.id, olderCall.toMap()),
          ],
          ('callerId', 'callee@example.com', null) => const [],
          ('calleeIds', null, 'callee@example.com') => [
            MapEntry(aliasDuplicate.id, aliasDuplicate.toMap()),
            MapEntry(olderCall.id, olderCall.toMap()),
          ],
          _ => const <MapEntry<String, Map<String, dynamic>>>[],
        };
        final query = _HistoryQuery(documents);
        historyQueries.add(query);
        return query;
      });

      final firstPage = await repository.getCallHistoryPage(
        currentUserId: 'callee-uid',
        pageSize: 2,
        opponentId: 'peer@example.com',
      );
      final secondPage = await repository.getCallHistoryPage(
        currentUserId: 'callee-uid',
        pageSize: 2,
        opponentId: 'peer@example.com',
        cursor: firstPage.nextCursor,
      );

      expect(
        queryFilters,
        containsAll([
          (field: 'callerId', isEqualTo: 'callee-uid', arrayContains: null),
          (field: 'calleeIds', isEqualTo: null, arrayContains: 'callee-uid'),
          (field: 'callerId', isEqualTo: 'callee@example.com', arrayContains: null),
          (field: 'calleeIds', isEqualTo: null, arrayContains: 'callee@example.com'),
        ]),
      );
      expect(queryFilters, hasLength(8));
      expect(
        queryFilters.every(
          (filter) =>
              filter.isEqualTo != 'peer@example.com' && filter.arrayContains != 'peer@example.com',
        ),
        isTrue,
      );
      expect(firstPage.calls.map((call) => call.id), [
        'outgoing-match',
        'incoming-alias-duplicate',
      ]);
      expect(firstPage.hasMore, isTrue);
      expect(secondPage.calls.map((call) => call.id), ['incoming-older']);
      expect(secondPage.hasMore, isFalse);
      expect(historyQueries, hasLength(8));
      for (final query in historyQueries) {
        expect(query.orderByFields.map((order) => order.descending), [true, true]);
        expect(query.resultLimit, 3);
      }
      for (final query in historyQueries.skip(4)) {
        expect(query.cursorValues, [2000, 'incoming-alias-duplicate']);
      }
    },
  );

  test('group history pages use a deterministic timestamp and document-id cursor', () async {
    final newestCall = historyCall(
      id: 'group-b',
      callerId: callerId,
      calleeIds: const [calleeId],
      createdAt: DateTime.fromMillisecondsSinceEpoch(5000),
      isGroup: true,
      groupId: 'group-history',
    );
    final olderCall = historyCall(
      id: 'group-a',
      callerId: callerId,
      calleeIds: const [calleeId],
      createdAt: DateTime.fromMillisecondsSinceEpoch(5000),
      isGroup: true,
      groupId: 'group-history',
    );
    final issuedQueries = <_HistoryQuery>[];
    when(
      () => collection.where(
        any(),
        isEqualTo: any(named: 'isEqualTo'),
        arrayContains: any(named: 'arrayContains'),
      ),
    ).thenAnswer((_) {
      final query = _HistoryQuery([
        MapEntry(newestCall.id, newestCall.toMap()),
        MapEntry(olderCall.id, olderCall.toMap()),
      ]);
      issuedQueries.add(query);
      return query;
    });

    final firstPage = await repository.getCallHistoryPage(
      currentUserId: callerId,
      groupId: 'group-history',
      pageSize: 1,
    );
    final secondPage = await repository.getCallHistoryPage(
      currentUserId: callerId,
      groupId: 'group-history',
      pageSize: 1,
      cursor: firstPage.nextCursor,
    );

    expect(firstPage.calls.map((call) => call.id), ['group-b']);
    expect(secondPage.calls.map((call) => call.id), ['group-a']);
    expect(secondPage.hasMore, isFalse);
    expect(issuedQueries, hasLength(2));
    expect(issuedQueries[0].resultLimit, 2);
    expect(issuedQueries[0].orderByFields.map((order) => order.descending), [true, true]);
    expect(issuedQueries[1].cursorValues, [5000, 'group-b']);
  });

  test('in-memory history pages preserve the ordering across cursor boundaries', () async {
    final inMemoryRepository = InMemoryCallRepository();
    for (final callId in ['call-a', 'call-b', 'call-c']) {
      await inMemoryRepository.startCall(
        callId: callId,
        callerId: 'caller@example.com',
        callerName: 'Caller',
        calleeIds: ['callee@example.com'],
        type: CallType.audio,
      );
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }

    final firstPage = await inMemoryRepository.getCallHistoryPage(
      currentUserId: 'callee@example.com',
      opponentId: 'caller@example.com',
      pageSize: 2,
    );
    final secondPage = await inMemoryRepository.getCallHistoryPage(
      currentUserId: 'callee@example.com',
      opponentId: 'caller@example.com',
      pageSize: 2,
      cursor: firstPage.nextCursor,
    );

    expect(firstPage.calls.map((call) => call.id), ['call-c', 'call-b']);
    expect(firstPage.hasMore, isTrue);
    expect(secondPage.calls.map((call) => call.id), ['call-a']);
    expect(secondPage.hasMore, isFalse);
  });

  test('getCallSession signs and returns the same UID for the local participant alias', () async {
    final requestUids = <int>[];
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final body = Map<String, dynamic>.from(options.data as Map);
            final uid = body['uid'] as int;
            requestUids.add(uid);
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {'token': 'signed-token', 'uid': uid, 'channelName': callId},
              ),
            );
          },
        ),
      );
    repository = FirestoreCallRepository(
      firestore: firestore,
      auth: auth,
      dio: dio,
      uidMapper: uidMapper,
    );

    final session = await repository.getCallSession(callId: callId, userId: 'callee-uid');
    final roster = Map<String, int>.from(session.extra['participants'] as Map);
    final expectedUid = uidMapper.toAgoraUid(calleeId);

    expect(requestUids, [expectedUid]);
    expect(session.extra['uid'], expectedUid);
    expect(roster[calleeId], expectedUid);
    expect(roster['callee-uid'], expectedUid);
    expect(session.extra['participantCanonicalIds'], containsPair('callee-uid', calleeId));
  });

  test('getCallSession rejects a token response signed for a different UID', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final body = Map<String, dynamic>.from(options.data as Map);
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'token': 'signed-token',
                  'uid': (body['uid'] as int) + 1,
                  'channelName': callId,
                },
              ),
            );
          },
        ),
      );
    repository = FirestoreCallRepository(
      firestore: firestore,
      auth: auth,
      dio: dio,
      uidMapper: uidMapper,
    );

    await expectLater(
      repository.getCallSession(callId: callId, userId: 'callee-uid'),
      throwsA(isA<StateError>()),
    );
  });

  test('startCall preserves case-sensitive Firebase UID identifiers', () async {
    when(() => collection.doc('uid-case-call')).thenReturn(documentReference);
    when(() => documentReference.set(any())).thenAnswer((_) async {});

    final call = await repository.startCall(
      callId: 'uid-case-call',
      callerId: 'CallerUIDCase',
      callerName: 'Caller',
      calleeIds: ['CalleeUIDCase'],
      type: CallType.audio,
    );

    expect(call.callerId, 'CallerUIDCase');
    expect(call.calleeIds, ['CalleeUIDCase']);
    expect(call.participants.map((participant) => participant.userId), [
      'CallerUIDCase',
      'CalleeUIDCase',
    ]);
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
