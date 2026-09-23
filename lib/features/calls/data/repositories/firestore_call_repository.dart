import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collab_tasks/features/calls/data/remote/agora/agora_config.dart';
import 'package:collab_tasks/features/calls/domain/models/call.dart';
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

  static const String _callsCollection = 'calls';

  FirestoreCallRepository({FirebaseFirestore? firestore, Uuid? uuid, Dio? dio, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _uuid = uuid ?? const Uuid(),
      _dio = dio ?? Dio(),
      _auth = auth ?? FirebaseAuth.instance;

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
    final normalizedUserId = userId.trim().toLowerCase();

    return _firestore
        .collection(_callsCollection)
        .where('calleeIds', arrayContains: normalizedUserId)
        .where('status', isEqualTo: CallStatus.ringing.name)
        .snapshots()
        .map((snapshot) {
          final calls = snapshot.docs
              .map((doc) => Call.fromMap(doc.data()))
              .where(
                (call) => call.participants.any(
                  (p) =>
                      p.userId.trim().toLowerCase() == normalizedUserId &&
                      p.status == CallParticipantStatus.ringing,
                ),
              )
              .toList();
          debugPrint(
            '[FirestoreCallRepository] Incoming ringing calls for $userId: ${calls.length}',
          );
          return calls;
        })
        .handleError((error) {
          debugPrint('[FirestoreCallRepository] Error in watchIncomingCalls($userId): $error');
          return <Call>[];
        });
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
    final normalizedCallerId = callerId.trim().toLowerCase();
    final normalizedCalleeIds = calleeIds.map((id) => id.trim().toLowerCase()).toList();

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
          displayName: 'User $id',
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
    final normalizedUserId = userId.trim().toLowerCase();
    debugPrint('[FirestoreCallRepository] acceptCall: callId=$callId, user=$normalizedUserId');

    final docRef = _firestore.collection(_callsCollection).doc(callId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Call $callId does not exist');
      }

      final call = Call.fromMap(snapshot.data()!);
      final updatedParticipants = call.participants.map((p) {
        if (p.userId.trim().toLowerCase() == normalizedUserId) {
          return p.copyWith(status: CallParticipantStatus.connected, joinedAt: DateTime.now());
        }
        return p;
      }).toList();

      final updatedCall = call.copyWith(
        status: CallStatus.active,
        startedAt: call.startedAt ?? DateTime.now(),
        participants: updatedParticipants,
      );

      transaction.update(docRef, updatedCall.toMap());
    });

    debugPrint('[FirestoreCallRepository] Call $callId accepted and set to active');
  }

  @override
  Future<void> rejectCall({required String callId, required String userId}) async {
    final normalizedUserId = userId.trim().toLowerCase();
    debugPrint('[FirestoreCallRepository] rejectCall: callId=$callId, user=$normalizedUserId');

    final docRef = _firestore.collection(_callsCollection).doc(callId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) return;

      final call = Call.fromMap(snapshot.data()!);
      final updatedParticipants = call.participants.map((p) {
        if (p.userId.trim().toLowerCase() == normalizedUserId) {
          return p.copyWith(status: CallParticipantStatus.declined);
        }
        return p;
      }).toList();

      final nonHostParticipants = updatedParticipants.where(
        (p) => p.role != CallParticipantRole.host,
      );
      final allDeclined =
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

    await docRef
        .update({
          'status': CallStatus.ended.name,
          'endedAtMillis': DateTime.now().millisecondsSinceEpoch,
        })
        .catchError((e) {
          debugPrint('[FirestoreCallRepository] Failed to update endCall for $callId: $e');
        });
  }

  @override
  Future<void> cancelCall(String callId) async {
    debugPrint('[FirestoreCallRepository] cancelCall: $callId');
    final docRef = _firestore.collection(_callsCollection).doc(callId);

    await docRef
        .update({
          'status': CallStatus.cancelled.name,
          'endedAtMillis': DateTime.now().millisecondsSinceEpoch,
        })
        .catchError((e) {
          debugPrint('[FirestoreCallRepository] Failed to update cancelCall for $callId: $e');
        });
  }

  @override
  Future<void> leaveCall({required String callId, required String userId}) async {
    final normalizedUserId = userId.trim().toLowerCase();
    debugPrint('[FirestoreCallRepository] leaveCall: callId=$callId, user=$normalizedUserId');

    final docRef = _firestore.collection(_callsCollection).doc(callId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) return;

      final call = Call.fromMap(snapshot.data()!);
      final updatedParticipants = call.participants.map<CallParticipant>((p) {
        if (p.userId.trim().toLowerCase() == normalizedUserId) {
          return p.copyWith(status: CallParticipantStatus.left);
        }
        return p;
      }).toList();

      final remainingConnected = updatedParticipants.where(
        (p) => p.status == CallParticipantStatus.connected,
      );

      final shouldEnd =
          remainingConnected.isEmpty || (!call.isGroup && remainingConnected.length < 2);

      final updatedCall = call.copyWith(
        status: shouldEnd ? CallStatus.ended : call.status,
        endedAt: shouldEnd ? DateTime.now() : null,
        participants: updatedParticipants,
      );

      transaction.update(docRef, updatedCall.toMap());
    });
  }

  @override
  Future<void> inviteParticipant({
    required String callId,
    required String userId,
    required String displayName,
    String? avatarUrl,
  }) async {
    final normalizedUserId = userId.trim().toLowerCase();
    debugPrint('[FirestoreCallRepository] inviteParticipant: $normalizedUserId to $callId');

    final docRef = _firestore.collection(_callsCollection).doc(callId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) return;

      final call = Call.fromMap(snapshot.data()!);
      if (call.participants.any((p) => p.userId.trim().toLowerCase() == normalizedUserId)) {
        return;
      }

      final newParticipant = CallParticipant(
        userId: normalizedUserId,
        displayName: displayName,
        avatarUrl: avatarUrl,
        role: CallParticipantRole.participant,
        status: CallParticipantStatus.ringing,
      );

      final updatedCalleeIds = List<String>.from(call.calleeIds);
      if (!updatedCalleeIds.contains(normalizedUserId)) {
        updatedCalleeIds.add(normalizedUserId);
      }

      final updatedCall = call.copyWith(
        calleeIds: updatedCalleeIds,
        participants: [...call.participants, newParticipant],
      );

      transaction.update(docRef, updatedCall.toMap());
    });
  }

  @override
  Future<CallSession> getCallSession({required String callId, required String userId}) async {
    debugPrint('[FirestoreCallRepository] getCallSession: callId=$callId, user=$userId');

    final call = await getCallById(callId);
    final mediaType = call?.type.name ?? 'audio';

    // Compute the Agora UID for this user — must match what AgoraRtcService uses
    // so that the generated token binds to the correct UID.
    final localUid = _computeAgoraUid(userId);
    debugPrint('[FirestoreCallRepository] localUid for $userId = $localUid');

    // Obtain Firebase ID token to authenticate the Cloud Function request
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('[FirestoreCallRepository] No authenticated user for token request');
    }

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
        'appId': AgoraConfig.appId,
        // Pass the int UID so AgoraRtcService uses the same value in joinChannel
        'uid': localUid,
      },
    );
  }

  @override
  Future<Call?> getCallById(String callId) async {
    final doc = await _firestore.collection(_callsCollection).doc(callId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Call.fromMap(doc.data()!);
  }

  /// Computes a deterministic positive 31-bit Agora UID from [userId].
  /// Must mirror [AgoraUidMapper.toAgoraUid] exactly so token and joinChannel use the same value.
  static int _computeAgoraUid(String userId) {
    int uid = userId.hashCode & 0x7FFFFFFF;
    if (uid == 0) uid = 1;
    return uid;
  }
}
