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
  Stream<List<WorkingGroup>> watchGroups({required String userId}) {
    return _groupsRef()
        .where('participantUserIds', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WorkingGroup.fromMap(_withId(doc)))
              .toList(growable: false),
        );
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
    required List<String> participantUserIds,
  }) {
    return _groupsRef().doc(group.id).set({
      ...group.toMap(participantUserIds: participantUserIds),
      'createdAt': Timestamp.fromDate(group.createdAt),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> upsertParticipant(GroupParticipant participant) async {
    await _participantsRef(participant.groupId).doc(participant.id).set(participant.toMap());
    await _groupsRef().doc(participant.groupId).set({
      'participantUserIds': FieldValue.arrayUnion([participant.userId]),
    }, SetOptions(merge: true));
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
