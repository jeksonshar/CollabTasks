import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collab_tasks/core/paging/chats_paging_constants.dart';
import 'package:collab_tasks/features/chats/data/remote/chat_remote_data_source.dart';
import 'package:collab_tasks/features/chats/data/remote/models/chat_dto.dart';
import 'package:collab_tasks/features/chats/data/remote/models/group_chat_dto.dart';
import 'package:collab_tasks/features/chats/data/remote/models/message_dto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class FirebaseChatRemoteDataSource implements ChatRemoteDataSource {
  final FirebaseFirestore _firestore;

  /// Должно совпадать с [FirebaseWorkingGroupsRemoteDataSource._groupsCollection]!!!
  static const _workingGroupsCollection = 'workingGroups';
  static const _groupMessagesSubcollection = 'messages';

  const FirebaseChatRemoteDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  @override
  Stream<List<MessageDto>> watchMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAtMillis', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => MessageDto.fromFirestore(doc.data(), doc.id)).toList();
        });
  }

  @override
  Future<void> sendMessage(String chatId, MessageDto message) async {
    final batch = _firestore.batch();

    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id);

    final chatRef = _firestore.collection('chats').doc(chatId);

    batch
      ..set(messageRef, message.toFirestore())
      ..update(chatRef, {'lastMessage': message.text, 'updatedAtMillis': message.createdAtMillis});

    await batch.commit();
  }

  @override
  Stream<List<MessageDto>> watchGroupMessages(String groupId) {
    return _firestore
        .collection(_workingGroupsCollection)
        .doc(groupId)
        .collection(_groupMessagesSubcollection)
        .orderBy('createdAtMillis', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => MessageDto.fromFirestore(doc.data(), doc.id)).toList();
        });
  }

  @override
  Future<void> sendGroupMessage(String groupId, MessageDto message) async {
    final messagesRef = _firestore
        .collection(_workingGroupsCollection)
        .doc(groupId)
        .collection(_groupMessagesSubcollection);

    final messageRef = message.id.isNotEmpty ? messagesRef.doc(message.id) : messagesRef.doc();

    await messageRef.set(message.toFirestore());
  }

  @override
  Future<List<ChatDto>> getChats(String userId) async {
    final snapshot = await _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .get();

    return snapshot.docs.map((doc) => ChatDto.fromFirestore(doc.data(), doc.id)).toList();
  }

  @override
  Future<String> getOrCreateDirectChat(String targetUserId) async {
    // final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final currentUserId = FirebaseAuth.instance.currentUser?.email;
    if (currentUserId == null) {
      throw StateError('User not authenticated');
    }

    debugPrint('=== [CHAT_DEBUG] ===');
    debugPrint('Current User ID (Я): $currentUserId');
    debugPrint('Target User ID (Собеседник): $targetUserId');

    // Запрос ищет все чаты типа direct, где есть текущий пользователь
    final querySnapshot = await _firestore
        .collection('chats')
        .where('type', isEqualTo: 'direct')
        .where('participantIds', arrayContains: currentUserId)
        .get();

    debugPrint('Found chats containing current user: ${querySnapshot.docs.length}');

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      // Безопасное извлечение списка через dynamic-лист, чтобы избежать ошибок кастинга
      final participantsRaw = data['participantIds'];
      if (participantsRaw is List) {
        final participantIds = participantsRaw.map((e) => e.toString()).toList();

        debugPrint('Checking doc ID: ${doc.id} with participants: $participantIds');

        // Чат должен содержать ровно 2 участников, и в нем должен быть targetUserId
        if (participantIds.length == 2 && participantIds.contains(targetUserId)) {
          debugPrint('SUCCESS: Found existing match! Room ID: ${doc.id}');
          debugPrint('====================');
          return doc.id;
        }
      }
    }

    debugPrint('WARNING: No match found. Creating a NEW room.');
    debugPrint('====================');

    // Если чат не найден — создаем один общий документ
    final newDocRef = _firestore.collection('chats').doc();
    await newDocRef.set({
      'type': 'direct',
      'participantIds': [currentUserId, targetUserId],
      'lastMessage': '',
      'updatedAtMillis': DateTime.now().millisecondsSinceEpoch,
    });

    return newDocRef.id;
  }

  @override
  Future<ChatDto?> getChatById(String chatId) async {
    try {
      final docSnapshot = await _firestore.collection('chats').doc(chatId).get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return null; // Или бросать кастомный DataException
      }

      return ChatDto.fromFirestore(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      // Логируем или прокидываем ошибку дальше в репозиторий
      throw Exception('Failed to fetch chat by id: $e');
    }
  }

  @override
  Future<GroupChatDto?> getGroupChatById(String chatId) async {
    try {
      final docSnapshot = await _firestore.collection('workingGroups').doc(chatId).get();
      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return null; // Или бросать кастомный DataException
      }

      return GroupChatDto.fromFirestore(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to fetch group chat by id: $e');
    }
  }

  @override
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).delete();
  }

  @override
  Future<bool> loadMoreMessages(
    String chatId, {
    required int beforeCreatedAtMillis,
    required String beforeId,
    int limit = limitOnPage,
  }) async {
    return false;
  }

  @override
  Future<bool> loadMoreGroupMessages(
    String groupId, {
    required int beforeCreatedAtMillis,
    required String beforeId,
    int limit = limitOnPage,
  }) async {
    return false;
  }
}
