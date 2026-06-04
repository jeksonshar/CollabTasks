import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collab_tasks/features/tasks/data/remote/remote_task_mapper.dart';
import 'package:collab_tasks/features/tasks/data/remote/task_attachment_binary_reader.dart';
import 'package:collab_tasks/features/tasks/data/remote/tasks_remote_data_source.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' hide Task;

class FirebaseRemoteDataSource implements TasksRemoteDataSource {
  static const String _usersCollection = 'users';
  static const String _tasksCollection = 'tasks';

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  const FirebaseRemoteDataSource({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _storage = storage,
       _auth = auth;

  @override
  Future<List<Task>> getTasks({required String ownerId}) async {
    final snapshot = await _tasksRef(ownerId).get();
    return snapshot.docs
        .map((doc) => RemoteTaskMapper.fromRemoteMap(_firestoreMap(doc)))
        .toList(growable: false);
  }

  @override
  Future<Task?> getTask({required String ownerId, required String taskId}) async {
    final doc = await _tasksRef(ownerId).doc(taskId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return RemoteTaskMapper.fromRemoteMap(_firestoreMap(doc));
  }

  @override
  Future<void> createTask({required String ownerId, required Task task}) async {
    await _tasksRef(ownerId).doc(task.id).set(_toFirestoreMap(task, ownerId: ownerId));
  }

  @override
  Future<void> updateTask({required String ownerId, required Task task}) async {
    await _tasksRef(ownerId).doc(task.id).set(_toFirestoreMap(task, ownerId: ownerId));
  }

  @override
  Future<void> deleteTask({required String ownerId, required String taskId}) async {
    await _tasksRef(ownerId).doc(taskId).delete();
  }

  @override
  Future<TaskAttachment> uploadFile({required String taskId, required TaskAttachment file}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Firebase uploadFile requires an authenticated user.');
    }
    final ownerId = user.uid;

    final bytes = file.bytes ?? await readTaskAttachmentBytes(file.localPath);
    if (bytes == null) {
      throw UnsupportedError('Firebase uploadFile requires bytes or a readable localPath.');
    }

    final storageKey = 'users/$ownerId/tasks/$taskId/files/$file.id-$file.name';
    final ref = _storage.ref(storageKey);
    await ref.putData(bytes);
    return file.copyWith(storageKey: storageKey);
  }

  CollectionReference<Map<String, dynamic>> _tasksRef(String ownerId) {
    return _firestore.collection(_usersCollection).doc(ownerId).collection(_tasksCollection);
  }

  Map<String, dynamic> _toFirestoreMap(Task task, {required String ownerId}) {
    final map = RemoteTaskMapper.toRemoteMap(task, ownerId: ownerId);
    return {
      ...map,
      'deadline': task.deadline == null ? null : Timestamp.fromDate(task.deadline!),
      'createdAt': Timestamp.fromDate(task.createdAt),
    };
  }

  Map<String, dynamic> _firestoreMap(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return {
      ...data,
      'id': doc.id,
      'createdAt': _timestampToMillis(data['createdAt']),
      'deadline': _timestampToMillis(data['deadline']),
    };
  }

  int? _timestampToMillis(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }
}
