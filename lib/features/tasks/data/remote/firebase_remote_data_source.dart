import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collab_tasks/features/tasks/data/remote/remote_task_mapper.dart';
import 'package:collab_tasks/features/tasks/data/remote/task_attachment_binary_reader.dart';
import 'package:collab_tasks/features/tasks/data/remote/tasks_remote_data_source.dart';
import 'package:collab_tasks/features/tasks/domain/models/task.dart';
import 'package:collab_tasks/features/tasks/domain/models/task_attachment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' hide Task;
import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;

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

  @override
  Future<Uint8List> downloadAttachmentBytes(String storageKey) async {
    try {
      debugPrint('downloadAttachmentBytes() 0');
      // В Firebase storageKey — это обычно полный путь к файлу внутри бакета (например, "uploads/tasks/file.pdf")
      final ref = _storage.ref().child(storageKey);
      debugPrint('downloadAttachmentBytes() 1');

      // Получаем байты напрямую через Firebase SDK.
      // 20 * 1024 * 1024 — это максимальный размер файла (20 МБ), настрой под себя.
      final Uint8List? data = await ref.getData(20 * 1024 * 1024);
      debugPrint('downloadAttachmentBytes() 2');

      if (data == null) {
        throw Exception('Firebase Storage вернул пустые байты');
      }
      return data;
    } catch (e) {
      throw Exception('Ошибка Firebase Storage при скачивании файла: $e');
    }
  }

  // @override
  // Future<Uint8List> downloadAttachmentBytes(String storageKey) async {
  //   final ref = _storage.ref().child(storageKey);
  //   debugPrint('downloadAttachmentBytes() 0');
  //   if (kIsWeb) {
  //     // 1. Получаем публичный URL (работает без CORS)
  //     final url = await ref.getDownloadURL();
  //     debugPrint('downloadAttachmentBytes() 1');
  //     // 2. Скачиваем байты по ссылке через HTTP (нужен настроенный CORS на сервере)
  //     final response = await http.get(Uri.parse(url));
  //     debugPrint('downloadAttachmentBytes() 2');
  //     if (response.statusCode == 200) {
  //       return response.bodyBytes; // Это и есть Uint8List
  //     } else {
  //       throw Exception('Не удалось скачать файл через HTTP: ${response.statusCode}');
  //     }
  //   } else {
  //     // НА МОБИЛКАХ: Firebase SDK работает стабильно и без CORS
  //     final Uint8List? data = await ref.getData(20 * 1024 * 1024);
  //     if (data == null) throw Exception('Пустые байты от Firebase');
  //     return data;
  //   }
  // }

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
