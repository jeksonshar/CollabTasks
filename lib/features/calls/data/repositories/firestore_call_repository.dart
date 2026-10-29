import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collab_tasks/features/calls/data/remote/agora/agora_config.dart';
import 'package:collab_tasks/features/calls/data/remote/agora/agora_uid_mapper.dart';
import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:collab_tasks/features/calls/domain/models/call_identity.dart';
import 'package:collab_tasks/features/calls/domain/models/call_participant.dart';
import 'package:collab_tasks/features/calls/domain/models/call_session.dart';
import 'package:collab_tasks/features/calls/domain/models/call_status.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:collab_tasks/features/calls/domain/repositories/call_repository.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class FirestoreCallRepository implements CallRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final Dio _dio;
  final FirebaseAuth _auth;
  final AgoraUidMapper _agoraUidMapper;

  static const String _callsCollection = 'calls';

  FirestoreCallRepository({
    FirebaseFirestore? firestore,
    Uuid? uuid,
    Dio? dio,
    FirebaseAuth? auth,
    AgoraUidMapper? uidMapper,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _uuid = uuid ?? const Uuid(),
       _dio = dio ?? Dio(),
       _auth = auth ?? FirebaseAuth.instance,
       _agoraUidMapper = uidMapper ?? AgoraUidMapper();

  @override
  Stream<Call?> watchActiveCall(String callId) {
    debugPrint('[FirestoreCallRepository] watchActiveCall: $callId');
    return _firestore
        .collection(_callsCollection)
        .doc(callId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            debugPrint('[FirestoreCallRepository] Call $callId does not exist or removed');
            return null;
          }
          return Call.fromMap(snapshot.data()!);
        })
        .handleError((error) {
          debugPrint('[FirestoreCallRepository] Error in watchActiveCall($callId): $error');
          return null;
        });
  }

  @override
  Stream<List<Call>> watchIncomingCalls(String userId) {
    debugPrint('[FirestoreCallRepository] watchIncomingCalls for user: $userId');
    final normalizedUserId = _normalizeIdentity(userId);
    final identities = <String>{normalizedUserId};
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      identities
        ..add(currentUser.uid.trim())
        ..add(currentUser.email?.trim().toLowerCase() ?? '')
        ..remove('');
    }

    final callsByQuery = <String, Map<String, Call>>{};
    final querySubscriptions = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    List<Call> filterAndCombine() {
      final combined = <String, Call>{};
      for (final results in callsByQuery.values) {
        combined.addAll(results);
      }
      final filtered = combined.values
          .where(
            (call) =>
                !identities.contains(_normalizeIdentity(call.callerId)) &&
                call.participants.any(
                  (p) =>
                      identities.contains(_normalizeIdentity(p.userId)) &&
                      p.status == CallParticipantStatus.ringing,
                ),
          )
          .toList();
      debugPrint(
        '[FirestoreCallRepository] Incoming ringing calls for $userId: ${filtered.length}',
      );
      return filtered;
    }

    // UID and email can both appear in calleeIds in existing documents. Keep
    // each query's latest snapshot so either identity can discover the call.
    late final StreamController<List<Call>> controller;
    controller = StreamController<List<Call>>(
      onListen: () {
        for (final identity in identities) {
          for (final status in [CallStatus.ringing, CallStatus.active]) {
            final queryKey = '${status.name}:$identity';
            final query = _firestore
                .collection(_callsCollection)
                .where('calleeIds', arrayContains: identity)
                .where('status', isEqualTo: status.name);
            querySubscriptions.add(
              query.snapshots().listen(
                (snapshot) {
                  callsByQuery[queryKey] = {
                    for (final doc in snapshot.docs) doc.id: Call.fromMap(doc.data()),
                  };
                  if (!controller.isClosed) controller.add(filterAndCombine());
                },
                onError: (error) {
                  debugPrint(
                    '[FirestoreCallRepository] Error in ${status.name} stream($identity): $error',
                  );
                },
              ),
            );
          }
        }
      },
      onCancel: () {
        for (final subscription in querySubscriptions) {
          unawaited(subscription.cancel());
        }
        controller.close();
      },
    );

    return controller.stream;
  }

  @override
  Future<Call> startCall({
    String? callId,
    required String callerId,
    required String callerName,
    String? callerAvatarUrl,
    required List<String> calleeIds,
    required CallType type,
    bool isGroup = false,
    String? groupId,
  }) async {
    final now = DateTime.now();
    final effectiveCallId = callId ?? _uuid.v4();
    final normalizedCallerId = normalizeCallIdentity(callerId);
    final normalizedCalleeIds = calleeIds
        .map(normalizeCallIdentity)
        .where((id) => id != normalizedCallerId)
        .toSet()
        .toList();

    debugPrint(
      '[FirestoreCallRepository] startCall: ID=$effectiveCallId, caller=$normalizedCallerId, callees=$normalizedCalleeIds, type=$type',
    );

    final participants = [
      CallParticipant(
        userId: normalizedCallerId,
        displayName: callerName,
        avatarUrl: callerAvatarUrl,
        role: CallParticipantRole.host,
        status: CallParticipantStatus.connected,
        joinedAt: now,
      ),
      ...normalizedCalleeIds.map(
        (id) => CallParticipant(
          userId: id,
          displayName: id,
          role: CallParticipantRole.participant,
          status: CallParticipantStatus.ringing,
        ),
      ),
    ];

    final call = Call(
      id: effectiveCallId,
      callerId: normalizedCallerId,
      callerName: callerName,
      callerAvatarUrl: callerAvatarUrl,
      calleeIds: normalizedCalleeIds,
      type: type,
      status: CallStatus.ringing,
      isGroup: isGroup,
      groupId: groupId,
      participants: participants,
      createdAt: now,
    );

    await _firestore.collection(_callsCollection).doc(effectiveCallId).set(call.toMap());

    debugPrint('[FirestoreCallRepository] Call document created in Firestore: $effectiveCallId');
    return call;
  }

  @override
  Future<void> acceptCall({required String callId, required String userId}) async {
    final normalizedUserId = _normalizeIdentity(userId);
    debugPrint('[FirestoreCallRepository] acceptCall: callId=$callId, user=$normalizedUserId');

    final docRef = _firestore.collection(_callsCollection).doc(callId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Call $callId does not exist');
      }

      final call = Call.fromMap(snapshot.data()!);
      if (!_isCurrentUser(userId)) {
        throw StateError('User $normalizedUserId does not match the authenticated user');
      }
      final participantIndex = _findParticipantIndex(call, userId);
      final canAcceptActiveGroupInvite = call.status == CallStatus.active && call.isGroup;
      if ((!call.calleeIds.any((id) => _matchesUserIdentity(id, userId))) ||
          (call.status != CallStatus.ringing && !canAcceptActiveGroupInvite) ||
          participantIndex == -1 ||
          call.participants[participantIndex].status != CallParticipantStatus.ringing) {
        throw StateError('Call $callId is no longer ringing for $normalizedUserId');
      }

      final now = DateTime.now();
      final updatedParticipants = List<CallParticipant>.from(call.participants);
      updatedParticipants[participantIndex] = updatedParticipants[participantIndex].copyWith(
        status: CallParticipantStatus.connected,
        joinedAt: now,
      );

      final updatedCall = call.copyWith(
        status: call.status == CallStatus.ringing ? CallStatus.active : call.status,
        startedAt: call.status == CallStatus.ringing ? (call.startedAt ?? now) : call.startedAt,
        participants: updatedParticipants,
      );

      transaction.update(docRef, updatedCall.toMap());
    });

    debugPrint('[FirestoreCallRepository] Call $callId accepted and set to active');
  }

  @override
  Future<void> rejectCall({required String callId, required String userId}) async {
    final normalizedUserId = _normalizeIdentity(userId);
    debugPrint('[FirestoreCallRepository] rejectCall: callId=$callId, user=$normalizedUserId');

    final docRef = _firestore.collection(_callsCollection).doc(callId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Call $callId does not exist');
      }

      final call = Call.fromMap(snapshot.data()!);
      if (!_isCurrentUser(userId)) {
        throw StateError('User $normalizedUserId does not match the authenticated user');
      }
      final participantIndex = _findParticipantIndex(call, userId);
      if (participantIndex == -1 ||
          !call.calleeIds.any((id) => _matchesUserIdentity(id, userId)) ||
          (call.status != CallStatus.ringing &&
              !(call.status == CallStatus.active && call.isGroup)) ||
          call.participants[participantIndex].status != CallParticipantStatus.ringing) {
        throw StateError('Call $callId cannot be declined by $normalizedUserId');
      }

      final updatedParticipants = List<CallParticipant>.from(call.participants);
      updatedParticipants[participantIndex] = updatedParticipants[participantIndex].copyWith(
        status: CallParticipantStatus.declined,
      );

      final nonHostParticipants = updatedParticipants.where(
        (p) => p.role != CallParticipantRole.host,
      );
      final allDeclined =
          !call.isGroup &&
          call.calleeIds.length == 1 &&
          nonHostParticipants.isNotEmpty &&
          nonHostParticipants.every((p) => p.status == CallParticipantStatus.declined);

      final updatedCall = call.copyWith(
        status: allDeclined ? CallStatus.rejected : call.status,
        participants: updatedParticipants,
        endedAt: allDeclined ? DateTime.now() : null,
      );

      transaction.update(docRef, updatedCall.toMap());
    });

    debugPrint('[FirestoreCallRepository] Call $callId reject processed');
  }

  @override
  Future<void> endCall(String callId) async {
    debugPrint('[FirestoreCallRepository] endCall: $callId');
    final docRef = _firestore.collection(_callsCollection).doc(callId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Call $callId does not exist');
      }

      final call = Call.fromMap(snapshot.data()!);
      final isMember = _isCurrentUser(call.callerId) || call.calleeIds.any(_isCurrentUser);
      if (!isMember || (call.status != CallStatus.ringing && call.status != CallStatus.active)) {
        throw StateError('Call $callId cannot be ended by the current user');
      }

      transaction.update(docRef, {
        'status': CallStatus.ended.name,
        'endedAtMillis': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  @override
  Future<void> cancelCall(String callId) async {
    debugPrint('[FirestoreCallRepository] cancelCall: $callId');
    final docRef = _firestore.collection(_callsCollection).doc(callId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Call $callId does not exist');
      }

      final call = Call.fromMap(snapshot.data()!);
      if (!_isCurrentUser(call.callerId) || call.status != CallStatus.ringing) {
        throw StateError('Call $callId cannot be cancelled by the current user');
      }

      transaction.update(docRef, {
        'status': CallStatus.cancelled.name,
        'endedAtMillis': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  @override
  Future<void> leaveCall({required String callId, required String userId}) async {
    final normalizedUserId = _normalizeIdentity(userId);
    debugPrint('[FirestoreCallRepository] leaveCall: callId=$callId, user=$normalizedUserId');

    final docRef = _firestore.collection(_callsCollection).doc(callId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Call $callId does not exist');
      }

      final call = Call.fromMap(snapshot.data()!);
      if (!_isCurrentUser(userId)) {
        throw StateError('User $normalizedUserId does not match the authenticated user');
      }
      final participantIndex = _findParticipantIndex(call, userId);
      if (participantIndex == -1 ||
          (call.status != CallStatus.ringing && call.status != CallStatus.active)) {
        throw StateError('Call $callId cannot be left by $normalizedUserId');
      }
      final leavingParticipant = call.participants[participantIndex];
      if (leavingParticipant.status != CallParticipantStatus.connected &&
          leavingParticipant.status != CallParticipantStatus.ringing) {
        throw StateError('Call $callId cannot be left by $normalizedUserId');
      }
      final updatedParticipants = List<CallParticipant>.from(call.participants);
      updatedParticipants[participantIndex] = leavingParticipant.copyWith(
        status: CallParticipantStatus.left,
      );

      final updatedCalleeIds = _isCurrentUser(call.callerId)
          ? List<String>.from(call.calleeIds)
          : call.calleeIds.where((id) => !_matchesUserIdentity(id, userId)).toList();

      final updatedCall = call.copyWith(
        calleeIds: updatedCalleeIds,
        participants: updatedParticipants,
      );

      final updatedCallData = updatedCall.toMap();
      transaction.update(docRef, {
        'calleeIds': updatedCallData['calleeIds'],
        'participantsByUser': updatedCallData['participantsByUser'],
      });
    });
  }

  @override
  Future<void> inviteParticipant({
    required String callId,
    required String userId,
    required String displayName,
    String? avatarUrl,
  }) async {
    final normalizedUserId = _normalizeIdentity(userId);
    debugPrint('[FirestoreCallRepository] inviteParticipant: $normalizedUserId to $callId');

    final docRef = _firestore.collection(_callsCollection).doc(callId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Call $callId does not exist');
      }

      final call = Call.fromMap(snapshot.data()!);
      final isConnectedGroupParticipant = call.participants.any(
        (participant) =>
            participant.status == CallParticipantStatus.connected &&
            _isCurrentUser(participant.userId),
      );
      if (!call.isGroup ||
          (call.status != CallStatus.ringing && call.status != CallStatus.active) ||
          (!_isCurrentUser(call.callerId) &&
              !(call.status == CallStatus.active && isConnectedGroupParticipant))) {
        throw StateError('Call $callId does not allow participant invitations');
      }
      final existingIndex = call.participants.indexWhere(
        (p) => _normalizeIdentity(p.userId) == normalizedUserId,
      );

      final List<CallParticipant> updatedParticipants;
      if (existingIndex != -1) {
        final existing = call.participants[existingIndex];
        if (existing.status == CallParticipantStatus.connected ||
            existing.status == CallParticipantStatus.ringing ||
            (existing.status != CallParticipantStatus.left &&
                existing.status != CallParticipantStatus.declined)) {
          throw StateError('Participant $normalizedUserId cannot be invited to call $callId');
        }
        final reInvited = CallParticipant(
          userId: existing.userId,
          displayName: displayName.isNotEmpty ? displayName : existing.displayName,
          avatarUrl: avatarUrl ?? existing.avatarUrl,
          role: CallParticipantRole.participant,
          status: CallParticipantStatus.ringing,
          // A previous joinedAt belongs to the old participation interval.
          // Rules require a fresh ringing invite to have no join timestamp.
          joinedAt: null,
        );
        updatedParticipants = List<CallParticipant>.from(call.participants);
        updatedParticipants[existingIndex] = reInvited;
      } else {
        final newParticipant = CallParticipant(
          userId: normalizedUserId,
          displayName: displayName,
          avatarUrl: avatarUrl,
          role: CallParticipantRole.participant,
          status: CallParticipantStatus.ringing,
        );
        updatedParticipants = [...call.participants, newParticipant];
      }

      final updatedCalleeIds = List<String>.from(call.calleeIds);
      if (!updatedCalleeIds.contains(normalizedUserId)) {
        updatedCalleeIds.add(normalizedUserId);
      }

      final updatedCall = call.copyWith(
        calleeIds: updatedCalleeIds,
        participants: updatedParticipants,
        lastInvitedParticipantId: normalizedUserId,
      );

      final updatedCallData = updatedCall.toMap();
      transaction.update(docRef, {
        'calleeIds': updatedCallData['calleeIds'],
        'participantsByUser': updatedCallData['participantsByUser'],
        'lastInvitedParticipantId': updatedCallData['lastInvitedParticipantId'],
      });
    });
  }

  @override
  Future<CallSession> getCallSession({required String callId, required String userId}) async {
    debugPrint('[FirestoreCallRepository] getCallSession: callId=$callId, user=$userId');

    final call = await getCallById(callId);
    final mediaType = call?.type.name ?? 'audio';
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('[FirestoreCallRepository] No authenticated user for token request');
    }

    final participantIds = <String>{
      if (call != null) ...[
        call.callerId,
        ...call.calleeIds,
        ...call.participants.map((participant) => participant.userId),
      ],
    }..removeWhere((id) => normalizeCallIdentity(id).isEmpty);
    final canonicalLocalId = call == null
        ? _fallbackCanonicalIdentity(userId, currentUser)
        : _resolveLocalCallIdentity(call, userId, currentUser, participantIds);
    participantIds.add(canonicalLocalId);

    final aliases = <String, String>{};
    final authUid = currentUser.uid.trim();
    final authEmail = currentUser.email?.trim();
    if (authUid.isNotEmpty) {
      aliases[authUid] = canonicalLocalId;
    }
    if (authEmail != null && authEmail.isNotEmpty) {
      aliases[authEmail] = canonicalLocalId;
    }
    final participantsMap = _agoraUidMapper.mapCallParticipants(participantIds, aliases: aliases);
    final localUid = participantsMap[normalizeCallIdentity(userId)];
    if (localUid == null) {
      throw StateError('Authenticated user $userId is not represented in call $callId');
    }
    debugPrint('[FirestoreCallRepository] localUid for $canonicalLocalId = $localUid');

    // Obtain Firebase ID token to authenticate the Cloud Function request.
    String rtcToken = '';
    try {
      final idToken = await currentUser.getIdToken();
      final response = await _dio.post<Map<String, dynamic>>(
        AgoraConfig.tokenServerUrl,
        // Send real uid so the token is bound to the UID the client will use in joinChannel
        data: {'channelName': callId, 'uid': localUid},
        options: Options(
          headers: {'Authorization': 'Bearer $idToken', 'Content-Type': 'application/json'},
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      final responseData = response.data;
      if (response.statusCode == 200 && responseData != null) {
        rtcToken = (responseData['token'] as String?) ?? '';
        final signedUid = responseData['uid'];
        if (signedUid is! num || signedUid.toInt() != localUid) {
          throw StateError('Agora token UID $signedUid does not match the client UID $localUid');
        }
        debugPrint(
          '[FirestoreCallRepository] Agora token received for channel=$callId, uid=$localUid',
        );
      } else {
        debugPrint('[FirestoreCallRepository] Token server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('[FirestoreCallRepository] DioException fetching Agora token: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FirestoreCallRepository] Unexpected error fetching Agora token: $e');
      rethrow;
    }

    if (rtcToken.isEmpty) {
      throw StateError(
        '[FirestoreCallRepository] Empty Agora token returned — '
        'check AGORA_APP_ID / AGORA_APP_CERTIFICATE env vars on the server.',
      );
    }

    return CallSession(
      callId: callId,
      roomId: callId,
      // channel name = callId for Agora
      token: rtcToken,
      localUserId: userId,
      extra: {
        'provider': 'agora',
        'mediaType': mediaType,
        'isGroup': call?.isGroup ?? false,
        'callName': call?.callerName ?? '',
        'appId': AgoraConfig.appId,
        // Pass the int UID so AgoraRtcService uses the same value in joinChannel
        'uid': localUid,
        'participants': participantsMap,
        'participantCanonicalIds': _agoraUidMapper.canonicalIdsByIdentity,
      },
    );
  }

  @override
  Future<Call?> getCallById(String callId) async {
    final doc = await _firestore.collection(_callsCollection).doc(callId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Call.fromMap(doc.data()!);
  }

  String _fallbackCanonicalIdentity(String userId, User currentUser) {
    final uid = currentUser.uid.trim();
    final email = currentUser.email?.trim();
    final input = normalizeCallIdentity(userId);
    final aliases = <String>{
      if (uid.isNotEmpty) normalizeCallIdentity(uid),
      if (email != null && email.isNotEmpty) normalizeCallIdentity(email),
    };
    if (!aliases.contains(input)) {
      throw StateError('Cannot verify call identity "$userId" for the authenticated user');
    }
    // Firebase UID is the strongest stable key when a call document is absent.
    return uid.isNotEmpty ? normalizeCallIdentity(uid) : normalizeCallIdentity(email!);
  }

  String _resolveLocalCallIdentity(
    Call call,
    String userId,
    User currentUser,
    Set<String> participantIds,
  ) {
    final input = normalizeCallIdentity(userId);
    final authUid = normalizeCallIdentity(currentUser.uid);
    final authEmail = currentUser.email?.trim().isNotEmpty == true
        ? normalizeCallIdentity(currentUser.email!)
        : null;
    final authAliases = <String>{authUid, ?authEmail};
    if (!authAliases.contains(input)) {
      throw StateError('Cannot verify call identity "$userId" for the authenticated user');
    }

    final normalizedParticipantIds = participantIds.map(normalizeCallIdentity).toSet();
    // Firestore Rules prefer the authenticated email key when both aliases are
    // present. Use that same roster key as the canonical identity for this call.
    if (authEmail != null && normalizedParticipantIds.contains(authEmail)) {
      return authEmail;
    }
    if (normalizedParticipantIds.contains(authUid)) return authUid;
    if (normalizedParticipantIds.contains(input)) return input;

    throw StateError(
      'Authenticated user is not present in call ${call.id}; cannot choose a canonical Agora identity',
    );
  }

  int _findParticipantIndex(Call call, String userId) {
    return call.participants.indexWhere(
      (participant) => _matchesUserIdentity(participant.userId, userId),
    );
  }

  bool _matchesUserIdentity(String storedId, String requestedId) {
    final normalizedStoredId = _normalizeIdentity(storedId);
    final normalizedRequestedId = _normalizeIdentity(requestedId);
    return normalizedStoredId == normalizedRequestedId ||
        (_isCurrentUser(normalizedRequestedId) && _isCurrentUser(normalizedStoredId));
  }

  bool _isCurrentUser(String userId) {
    final normalized = _normalizeIdentity(userId);
    final currentUser = _auth.currentUser;
    return normalized == currentUser?.uid.trim() ||
        normalized == currentUser?.email?.trim().toLowerCase();
  }

  String _normalizeIdentity(String userId) {
    return normalizeCallIdentity(userId);
  }
}
