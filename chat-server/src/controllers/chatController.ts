// ============================================================
// src/controllers/chatController.ts
// Обработчик входящих WS-событий от аутентифицированных клиентов
// Реализует полный контракт ChatRemoteDataSource
// ============================================================

import { v4 as uuidv4 } from 'uuid';
import { AuthenticatedSocket, sendToClient, sendError, sendToUser } from '../websocket/connectionManager';
import {
  subscribe,
  unsubscribe,
  getSubscribers,
  chatTopicKey,
  groupTopicKey,
} from '../websocket/subscriptionManager';
import * as db from '../storage/db';
import {
  sendDirectChatPushNotification,
  sendGroupChatPushNotification,
} from '../services/pushNotificationService';
import {
  InboundEvent,
  ChatDto,
  MessageDto,
} from '../models/types';

// ─────────────────────────────────────────────────────────────
// Главная точка входа
// ─────────────────────────────────────────────────────────────

/**
 * Диспетчер входящих событий.
 * Вызывается из server.ts для каждого валидного JSON-сообщения.
 */
export async function handleEvent(
  client: AuthenticatedSocket,
  event: InboundEvent
): Promise<void> {
  switch (event.type) {
    case 'subscribe_topic':
      handleSubscribeTopic(client, event.topicId);
      break;

    case 'unsubscribe_topic':
      handleUnsubscribeTopic(client, event.topicId);
      break;

    case 'send_message':
      await handleSendMessage(client, event.chatId, event.message);
      break;

    case 'send_group_message':
      await handleSendGroupMessage(client, event.groupId, event.message);
      break;

    case 'get_chats':
      handleGetChats(client, event.userId);
      break;

    case 'get_or_create_direct_chat':
      await handleGetOrCreateDirectChat(client, event.targetUserId);
      break;

    case 'get_chat_by_id':
      handleGetChatById(client, event.chatId);
      break;

    case 'get_group_chat_by_id':
      handleGetGroupChatById(client, event.chatId);
      break;

    case 'delete_message':
      handleDeleteMessage(client, event.chatId, event.messageId);
      break;

    case 'sync_fcm_token':
      handleSyncFcmToken(client, event.token);
      break;

    default: {
      // Неизвестный тип события — явно сообщаем об ошибке
      const unknownType = (event as { type: string }).type;
      sendError(client, `Неизвестный тип события: ${unknownType}`);
      console.warn(
        `[ChatController] Неизвестный тип события от userId=${client.user.userId}: ${unknownType}`
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────
// subscribe_topic / unsubscribe_topic
// Зеркало: watchMessages(chatId) / watchGroupMessages(groupId)
// ─────────────────────────────────────────────────────────────

function handleSubscribeTopic(client: AuthenticatedSocket, topicId: string): void {
  if (!topicId) {
    sendError(client, 'subscribe_topic: topicId обязателен');
    return;
  }
  subscribe(client, topicId);

  // При подписке на чат — сразу отдаём историю сообщений
  if (topicId.startsWith('chat:')) {
    const chatId = topicId.slice(5);
    const messages = db.getMessages(chatId);
    // Отдаём все сообщения как серию new_message событий
    for (const message of messages.slice().reverse()) {
      sendToClient(client, { type: 'new_message', chatId, message });
    }
  } else if (topicId.startsWith('group:')) {
    const groupId = topicId.slice(6);
    const messages = db.getGroupMessages(groupId);
    for (const message of messages.slice().reverse()) {
      sendToClient(client, { type: 'new_group_message', groupId, message });
    }
  }
}

function handleUnsubscribeTopic(client: AuthenticatedSocket, topicId: string): void {
  if (!topicId) {
    sendError(client, 'unsubscribe_topic: topicId обязателен');
    return;
  }
  unsubscribe(client, topicId);
}

// ─────────────────────────────────────────────────────────────
// send_message
// Зеркало: sendMessage(chatId, message)
// ─────────────────────────────────────────────────────────────

async function handleSendMessage(
  client: AuthenticatedSocket,
  chatId: string,
  message: MessageDto
): Promise<void> {
  if (!chatId || !message?.id) {
    sendError(client, 'send_message: chatId и message.id обязательны');
    return;
  }

  // 1. Сохраняем сообщение в БД
  db.insertMessage(chatId, message);

  // 2. Обновляем lastMessage у чата
  db.updateChatLastMessage(chatId, message.text, message.createdAtMillis);

  // 3. Рассылаем всем подписчикам топика "chat:<chatId>"
  const topicId = chatTopicKey(chatId);
  const subscribers = getSubscribers(topicId);
  const outboundEvent = { type: 'new_message' as const, chatId, message };

  for (const subscriber of subscribers) {
    sendToClient(subscriber, outboundEvent);
  }

  console.log(
    `[ChatController] Сообщение в чате ${chatId} от ${client.user.userId} ` +
    `→ доставлено ${subscribers.length} подписчикам`
  );

  // 4. FCM для offline-получателей
  const chat = db.getChatById(chatId);
  if (chat) {
    await sendDirectChatPushNotification(
      chatId,
      message.senderId,
      message.senderName,
      message.text,
      chat.participantIds
    );
  }
}

// ─────────────────────────────────────────────────────────────
// send_group_message
// Зеркало: sendGroupMessage(groupId, message)
// ─────────────────────────────────────────────────────────────

async function handleSendGroupMessage(
  client: AuthenticatedSocket,
  groupId: string,
  message: MessageDto
): Promise<void> {
  if (!groupId || !message?.id) {
    sendError(client, 'send_group_message: groupId и message.id обязательны');
    return;
  }

  // 1. Сохраняем сообщение в БД
  db.insertGroupMessage(groupId, message);

  // 2. Рассылаем всем подписчикам топика "group:<groupId>"
  const topicId = groupTopicKey(groupId);
  const subscribers = getSubscribers(topicId);
  const outboundEvent = { type: 'new_group_message' as const, groupId, message };

  for (const subscriber of subscribers) {
    sendToClient(subscriber, outboundEvent);
  }

  console.log(
    `[ChatController] Сообщение в группе ${groupId} от ${client.user.userId} ` +
    `→ доставлено ${subscribers.length} подписчикам`
  );

  // 3. FCM для offline-участников
  const groupChat = db.getGroupChatById(groupId);
  if (groupChat) {
    await sendGroupChatPushNotification(
      groupId,
      message.senderId,
      message.senderName,
      message.text,
      groupChat.participantUserIds
    );
  }
}

// ─────────────────────────────────────────────────────────────
// get_chats
// Зеркало: getChats(userId)
// ─────────────────────────────────────────────────────────────

function handleGetChats(client: AuthenticatedSocket, userId: string): void {
  if (!userId) {
    sendError(client, 'get_chats: userId обязателен');
    return;
  }

  const userIds = [client.user.userId, client.user.email, userId].filter(Boolean);
  const chats = db.getChatsByUserId(userIds);
  sendToClient(client, { type: 'chat_list', chats });
}

// ─────────────────────────────────────────────────────────────
// get_or_create_direct_chat
// Зеркало: getOrCreateDirectChat(targetUserId)
// ─────────────────────────────────────────────────────────────

async function handleGetOrCreateDirectChat(
  client: AuthenticatedSocket,
  targetUserId: string
): Promise<void> {
  if (!targetUserId) {
    sendError(client, 'get_or_create_direct_chat: targetUserId обязателен');
    return;
  }

  const currentUserId = client.user.userId;
  const currentEmail = client.user.email;

  // Ищем существующий прямой чат между текущим пользователем (UID / email) и целевым пользователем
  const existingChat = db.findDirectChat(
    [currentUserId, currentEmail],
    [targetUserId]
  );

  if (existingChat) {
    sendToClient(client, { type: 'direct_chat_created', chatId: existingChat.id });
    return;
  }

  // Создаём новый чат. Предпочитаем email для единообразия, если он есть
  const primaryCurrentId = currentEmail || currentUserId;
  const newChatId = uuidv4();
  const newChat: ChatDto = {
    id: newChatId,
    type: 'direct',
    participantIds: [primaryCurrentId, targetUserId],
    lastMessage: '',
    updatedAtMillis: Date.now(),
  };

  db.upsertChat(newChat);

  console.log(
    `[ChatController] Создан прямой чат ${newChatId} ` +
    `между ${primaryCurrentId} и ${targetUserId}`
  );

  sendToClient(client, { type: 'direct_chat_created', chatId: newChatId });

  // Уведомляем targetUserId если он онлайн (по UID или email)
  sendToUser(targetUserId, { type: 'chat_list', chats: [newChat] });
}

// ─────────────────────────────────────────────────────────────
// get_chat_by_id
// Зеркало: getChatById(chatId)
// ─────────────────────────────────────────────────────────────

function handleGetChatById(client: AuthenticatedSocket, chatId: string): void {
  if (!chatId) {
    sendError(client, 'get_chat_by_id: chatId обязателен');
    return;
  }

  const chat = db.getChatById(chatId);
  sendToClient(client, { type: 'chat_by_id', chat });
}

// ─────────────────────────────────────────────────────────────
// get_group_chat_by_id
// Зеркало: getGroupChatById(chatId)
// ─────────────────────────────────────────────────────────────

function handleGetGroupChatById(client: AuthenticatedSocket, chatId: string): void {
  if (!chatId) {
    sendError(client, 'get_group_chat_by_id: chatId обязателен');
    return;
  }

  const chat = db.getGroupChatById(chatId);
  sendToClient(client, { type: 'group_chat_by_id', chat });
}

// ─────────────────────────────────────────────────────────────
// delete_message
// Зеркало: deleteMessage(chatId, messageId)
// ─────────────────────────────────────────────────────────────

function handleDeleteMessage(
  client: AuthenticatedSocket,
  chatId: string,
  messageId: string
): void {
  if (!chatId || !messageId) {
    sendError(client, 'delete_message: chatId и messageId обязательны');
    return;
  }

  db.deleteMessage(chatId, messageId);

  // Уведомляем всех подписчиков топика об удалении
  const topicId = chatTopicKey(chatId);
  const subscribers = getSubscribers(topicId);
  const outboundEvent = { type: 'message_deleted' as const, chatId, messageId };

  for (const subscriber of subscribers) {
    sendToClient(subscriber, outboundEvent);
  }

  console.log(
    `[ChatController] Сообщение ${messageId} удалено из чата ${chatId} ` +
    `пользователем ${client.user.userId}`
  );
}

// ─────────────────────────────────────────────────────────────
// sync_fcm_token
// Сохраняет FCM-токен устройства в локальную БД для offline push
// ─────────────────────────────────────────────────────────────

function handleSyncFcmToken(client: AuthenticatedSocket, token: string): void {
  if (!token || token.length < 20) {
    sendError(client, 'sync_fcm_token: token невалиден или пуст');
    return;
  }

  db.upsertFcmToken(client.user.userId, token);

  console.log(
    `[ChatController] FCM-токен синхронизирован для userId=${client.user.userId}: ` +
    `${token.slice(0, 20)}...`
  );
}
