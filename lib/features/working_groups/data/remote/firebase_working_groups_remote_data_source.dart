import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collab_tasks/features/working_groups/data/remote/working_groups_remote_data_source.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_participant.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task.dart';
import 'package:collab_tasks/features/working_groups/domain/models/group_task_assignment_exception.dart';
import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';

class FirebaseWorkingGroupsRemoteDataSource implements WorkingGroupsRemoteDataSource {
  const FirebaseWorkingGroupsRemoteDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  static const _groupsCollection = 'workingGroups';
  static const _participantsCollection = 'participants';
  static const _tasksCollection = 'tasks';

  final FirebaseFirestore _firestore;

  @override
  Stream<List<WorkingGroup>> watchGroups({required String userId, required String userEmail}) {
    final userIdGroups = _groupsRef()
        .where('participantUserIds', arrayContains: userId)
        .snapshots();
    final normalizedEmail = userEmail.trim().toLowerCase();
    final emailGroups = _groupsRef()
        .where('participantEmails', arrayContains: normalizedEmail)
        .snapshots();
    return Stream.multi((controller) {
      var groupsByUserId = <String, WorkingGroup>{};
      var groupsByEmail = <String, WorkingGroup>{};

      void emitCombined() {
        controller.add({...groupsByUserId, ...groupsByEmail}.values.toList(growable: false));
      }

      final subscriptions = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[
        userIdGroups.listen((snapshot) {
          groupsByUserId = _groupsFromSnapshot(snapshot);
          emitCombined();
        }, onError: controller.addError),
        emailGroups.listen((snapshot) {
          groupsByEmail = _groupsFromSnapshot(snapshot);
          emitCombined();
        }, onError: controller.addError),
      ];

      controller.onCancel = () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      };
    });
  }

  Map<String, WorkingGroup> _groupsFromSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return {for (final doc in snapshot.docs) doc.id: WorkingGroup.fromMap(_withId(doc))};
  }

  @override
  Stream<List<GroupParticipant>> watchParticipants({required String groupId}) {
    return _participantsRef(groupId).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => GroupParticipant.fromMap(_withId(doc)))
          .toList(growable: false),
    );
  }

  @override
  Stream<List<GroupTask>> watchTasks({required String groupId}) {
    return _tasksRef(groupId).snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => GroupTask.fromMap(_withId(doc))).toList(growable: false),
    );
  }

  @override
  Future<void> upsertGroup({
    required WorkingGroup group,
    List<String> participantUserIds = const [],
    List<String> participantEmails = const [],
  }) {
    final data = {...group.toMap(), 'createdAt': Timestamp.fromDate(group.createdAt)};
    if (participantUserIds.isNotEmpty) {
      data['participantUserIds'] = FieldValue.arrayUnion(participantUserIds);
    }
    if (participantEmails.isNotEmpty) {
      data['participantEmails'] = FieldValue.arrayUnion(
        participantEmails.map((email) => email.toLowerCase()).toList(growable: false),
      );
    }
    return _groupsRef().doc(group.id).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteGroup(String groupId) {
    return _groupsRef().doc(groupId).delete();
  }

  @override
  Future<void> inviteParticipantByEmail({required String groupId, required String email}) async {
    final normalizedEmail = email.trim().toLowerCase();
    await _groupsRef().doc(groupId).set({
      'participantEmails': FieldValue.arrayUnion([normalizedEmail]),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> upsertParticipant(GroupParticipant participant) async {
    await _participantsRef(participant.groupId).doc(participant.id).set(participant.toMap());
    if (participant.userId.contains('@')) return;
    await _groupsRef().doc(participant.groupId).set({
      'participantUserIds': FieldValue.arrayUnion([participant.userId]),
    }, SetOptions(merge: true));
  }

  @override
  Future<bool> isGroupMember({
    required String groupId,
    required String userId,
    required String userEmail,
  }) async {
    final snapshot = await _groupsRef().doc(groupId).get();
    final data = snapshot.data();
    if (data == null) return false;
    final normalizedEmail = userEmail.trim().toLowerCase();
    final userIds = (data['participantUserIds'] as List?)?.whereType<String>() ?? const <String>[];
    final emails = (data['participantEmails'] as List?)?.whereType<String>() ?? const <String>[];
    return userIds.contains(userId) ||
        emails.any((email) => email.trim().toLowerCase() == normalizedEmail);
  }

  @override
  Future<void> leaveGroup({
    required String groupId,
    required String userId,
    required String userEmail,
    required List<String> participantIds,
  }) async {
    final normalizedEmail = userEmail.trim().toLowerCase();
    final batch = _firestore.batch();
    final groupRef = _groupsRef().doc(groupId);

    batch.set(groupRef, {
      'participantUserIds': FieldValue.arrayRemove([userId]),
      'participantEmails': FieldValue.arrayRemove([normalizedEmail]),
    }, SetOptions(merge: true));

    for (final participantId in participantIds) {
      batch.delete(_participantsRef(groupId).doc(participantId));
    }

    await batch.commit();
  }

  @override
  Future<void> upsertTask(GroupTask task) {
    return _tasksRef(task.groupId).doc(task.id).set(task.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteTask({required String groupId, required String taskId}) {
    return _tasksRef(groupId).doc(taskId).delete();
  }

  @override
  Future<void> claimTask({
    required String groupId,
    required String taskId,
    required String participantId,
    required int updatedAt,
  }) async {
    final ref = _tasksRef(groupId).doc(taskId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      final assignedUserId = data?['assignedUserId'] as String?;
      if (assignedUserId != null && assignedUserId.isNotEmpty && assignedUserId != participantId) {
        throw const GroupTaskAssignmentException('Task is already claimed by another participant.');
      }
      transaction.set(ref, {
        'assignedUserId': participantId,
        'updatedAtMillis': updatedAt,
      }, SetOptions(merge: true));
    });
  }

  CollectionReference<Map<String, dynamic>> _groupsRef() =>
      _firestore.collection(_groupsCollection);

  CollectionReference<Map<String, dynamic>> _participantsRef(String groupId) {
    return _groupsRef().doc(groupId).collection(_participantsCollection);
  }

  CollectionReference<Map<String, dynamic>> _tasksRef(String groupId) {
    return _groupsRef().doc(groupId).collection(_tasksCollection);
  }

  Map<String, dynamic> _withId(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return {...data, 'id': doc.id, 'createdAt': _timestampToMillis(data['createdAt'])};
  }

  int? _timestampToMillis(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is num) return value.toInt();
    return null;
  }
}
