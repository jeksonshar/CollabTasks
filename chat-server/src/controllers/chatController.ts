// ============================================================
// src/controllers/chatController.ts
// Обработчик входящих WS-событий от аутентифицированных клиентов
// Реализует полный контракт ChatRemoteDataSource
// Адаптировано для асинхронного PostgreSQL API (storage/db.ts)
// ============================================================

import { v4 as uuidv4 } from 'uuid';
import {
  AuthenticatedSocket,
  sendToClient,
  sendError,
  sendToUser,
} from '../websocket/connectionManager';
import {
  subscribe,
  unsubscribe,
  getSubscribers,
  isUserSubscribed,
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
  GroupChatDto,
  MessageDto,
} from '../models/types';

// ─────────────────────────────────────────────────────────────
// Главная точка входа
// ─────────────────────────────────────────────────────────────

/** * Диспетчер входящих событий.
 * Вызывается из server.ts для каждого валидного JSON-сообщения.
 * ВСЕ ОБРАБОТЧИКИ ТЕПЕРЬ ASYNC И ВЫЗЫВАЮТСЯ С AWAIT
 */
export async function handleEvent(
    client: AuthenticatedSocket,
    event: InboundEvent
): Promise<void> {
  switch (event.type) {
    case 'subscribe_topic':
      // Добавлен await
      await handleSubscribeTopic(client, event.topicId);
      break;

    case 'unsubscribe_topic':
      // Добавлен await
      await handleUnsubscribeTopic(client, event.topicId);
      break;

    case 'send_message':
      await handleSendMessage(client, event.chatId, event.message);
      break;

    case 'send_group_message':
      await handleSendGroupMessage(client, event.groupId, event.message);
      break;

    case 'get_chats':
      // Добавлен await
      await handleGetChats(client, event.userId);
      break;

    case 'get_or_create_direct_chat':
      await handleGetOrCreateDirectChat(client, event.targetUserId);
      break;

    case 'get_chat_by_id':
      // Добавлен await
      await handleGetChatById(client, event.chatId);
      break;

    case 'get_group_chat_by_id':
      // Добавлен await
      await handleGetGroupChatById(client, event.chatId);
      break;

    case 'delete_message':
      // Добавлен await
      await handleDeleteMessage(client, event.chatId, event.messageId);
      break;

    case 'sync_fcm_token':
      // Добавлен await
      await handleSyncFcmToken(client, event.token);
      break;

    case 'remove_fcm_token':
      // Добавлен await
      await handleRemoveFcmToken(client, event.token);
      break;

    case 'upsert_group_chat':
      // Добавлен await
      await handleUpsertGroupChat(client, event.chat);
      break;

    case 'typing':
      //typing не лезет в БД, оставляем синхронным
      handleTyping(client, event.chatId, event.isTyping);
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

// Функция стала async
async function handleSubscribeTopic(client: AuthenticatedSocket, topicId: string): Promise<void> {
  if (!topicId) {
    sendError(client, 'subscribe_topic: topicId обязателен');
    return;
  }
  subscribe(client, topicId);

  // При подписке на чат — сразу отдаём историю сообщений и статус участников
  if (topicId.startsWith('chat:')) {
    const chatId = topicId.slice(5);
    // Добавлен await для db.getMessages
    const messages = await db.getMessages(chatId);
    // Отдаём все сообщения как серию new_message событий
    for (const message of messages.slice().reverse()) {
      sendToClient(client, { type: 'new_message', chatId, message });
    }

    const clientIdentifiers = [
      client.user.userId.trim().toLowerCase(),
      client.user.email.trim().toLowerCase(),
    ];

    // 1. Оповещаем остальных участников этого чата, что данный пользователь вошёл (online)
    const subscribers = getSubscribers(topicId);
    for (const sub of subscribers) {
      if (clientIdentifiers.includes(sub.user.userId.trim().toLowerCase())) continue;
      for (const id of clientIdentifiers) {
        sendToClient(sub, {
          type: 'user_status_changed',
          userId: id,
          status: 'online',
        });
      }
    }

    // 2. Отправляем актуальный статус собеседников вошедшему пользователю
    // Добавлен await для db.getChatById
    const chat = await db.getChatById(chatId);
    if (chat && chat.type === 'direct') {
      for (const participantId of chat.participantIds) {
        const normParticipant = participantId.trim().toLowerCase();
        if (clientIdentifiers.includes(normParticipant)) continue;

        // Пользователь онлайн в этом чате, если он сейчас подписан на данный топик
        const online = isUserSubscribed(normParticipant, topicId);
        // Добавлен await для db.getLastSeen
        const lastSeenMs = online ? undefined : await db.getLastSeen(normParticipant);

        sendToClient(client, {
          type: 'user_status_changed',
          userId: normParticipant,
          status: online ? 'online' : 'offline',
          ...(lastSeenMs && lastSeenMs > 0 ? { lastSeenMillis: lastSeenMs } : {}),
        });
      }
    }
  } else if (topicId.startsWith('group:')) {
    const groupId = topicId.slice(6);
    // Добавлен await для db.getGroupMessages
    const messages = await db.getGroupMessages(groupId);
    for (const message of messages.slice().reverse()) {
      sendToClient(client, { type: 'new_group_message', groupId, message });
    }
  }
}

// Функция стала async
async function handleUnsubscribeTopic(client: AuthenticatedSocket, topicId: string): Promise<void> {
  if (!topicId) {
    sendError(client, 'unsubscribe_topic: topicId обязателен');
    return;
  }
  unsubscribe(client, topicId);

  if (topicId.startsWith('chat:')) {
    // Пользователь вышел из чата — фиксируем время выхода
    const lastSeenMs = Date.now();
    // Добавлены await для db.upsertLastSeen
    await db.upsertLastSeen(client.user.userId, lastSeenMs);
    if (client.user.email) {
      await db.upsertLastSeen(client.user.email, lastSeenMs);
    }

    const clientIdentifiers = [
      client.user.userId.trim().toLowerCase(),
      client.user.email.trim().toLowerCase(),
    ];

    // Проверяем, не остался ли сокет с этого же аккаунта в данном топике
    const stillSubscribed = isUserSubscribed(client.user.userId, topicId);
    if (!stillSubscribed) {
      // Оповещаем оставшихся участников чата, что пользователь вышел (offline)
      const subscribers = getSubscribers(topicId);
      for (const sub of subscribers) {
        if (clientIdentifiers.includes(sub.user.userId.trim().toLowerCase())) continue;
        for (const id of clientIdentifiers) {
          sendToClient(sub, {
            type: 'user_status_changed',
            userId: id,
            status: 'offline',
            lastSeenMillis: lastSeenMs,
          });
        }
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────
// send_message
// Зеркало: sendMessage(chatId, message)
// ─────────────────────────────────────────────────────────────

// Функция уже была async, добавлены await внутри
async function handleSendMessage(
    client: AuthenticatedSocket,
    chatId: string,
    message: MessageDto
): Promise<void> {
  if (!chatId || !message?.id) {
    sendError(client, 'send_message: chatId и message.id обязательны');
    return;
  }

  // 1. Сохраняем сообщение в БД (добавлен await)
  await db.insertMessage(chatId, message);

  // 2. Обновляем lastMessage у чата (добавлен await)
  await db.updateChatLastMessage(chatId, message.text, message.createdAtMillis);

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
  // Добавлен await для db.getChatById
  const chat = await db.getChatById(chatId);
  if (chat) {
    // sendDirectChatPushNotification уже async и вызывается с await
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

// Функция уже была async, добавлены await внутри
async function handleSendGroupMessage(
    client: AuthenticatedSocket,
    groupId: string,
    message: MessageDto
): Promise<void> {
  if (!groupId || !message?.id) {
    sendError(client, 'send_group_message: groupId и message.id обязательны');
    return;
  }

  // 1. Сохраняем сообщение в БД (добавлен await)
  await db.insertGroupMessage(groupId, message);

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

  // 3. FCM для участников группы
  // Добавлен await для db.getGroupChatById
  const groupChat = await db.getGroupChatById(groupId);
  if (groupChat) {
    const allParticipants = [
      ...(groupChat.participantUserIds ?? []),
      ...(groupChat.participantEmails ?? []),
    ];
    // sendGroupChatPushNotification уже async и вызывается с await
    await sendGroupChatPushNotification(
        groupId,
        message.senderId,
        message.senderName,
        message.text,
        allParticipants
    );
  }
}

// ─────────────────────────────────────────────────────────────
// get_chats
// Зеркало: getChats(userId)
// ─────────────────────────────────────────────────────────────

// Функция стала async
async function handleGetChats(client: AuthenticatedSocket, userId: string): Promise<void> {
  if (!userId) {
    sendError(client, 'get_chats: userId обязателен');
    return;
  }

  const userIds = [client.user.userId, client.user.email, userId].filter(Boolean);
  // Добавлен await для db.getChatsByUserId
  const chats = await db.getChatsByUserId(userIds);
  sendToClient(client, { type: 'chat_list', chats });
}

// ─────────────────────────────────────────────────────────────
// get_or_create_direct_chat
// Зеркало: getOrCreateDirectChat(targetUserId)
// ─────────────────────────────────────────────────────────────

// Функция уже была async, добавлены await внутри
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

  // Ищем существующий прямой чат (добавлен await для db.findDirectChat)
  const existingChat = await db.findDirectChat(
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

  // Добавлен await для db.upsertChat
  await db.upsertChat(newChat);

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

// Функция стала async
async function handleGetChatById(client: AuthenticatedSocket, chatId: string): Promise<void> {
  if (!chatId) {
    sendError(client, 'get_chat_by_id: chatId обязателен');
    return;
  }

  // Добавлен await для db.getChatById
  const chat = await db.getChatById(chatId);
  sendToClient(client, { type: 'chat_by_id', chat });
}

// ─────────────────────────────────────────────────────────────
// get_group_chat_by_id
// Зеркало: getGroupChatById(chatId)
// ─────────────────────────────────────────────────────────────

// Функция стала async
async function handleGetGroupChatById(client: AuthenticatedSocket, chatId: string): Promise<void> {
  if (!chatId) {
    sendError(client, 'get_group_chat_by_id: chatId обязателен');
    return;
  }

  // Добавлен await для db.getGroupChatById
  const chat = await db.getGroupChatById(chatId);
  sendToClient(client, { type: 'group_chat_by_id', chat });
}

// ─────────────────────────────────────────────────────────────
// delete_message
// Зеркало: deleteMessage(chatId, messageId)
// ─────────────────────────────────────────────────────────────

// Функция стала async
async function handleDeleteMessage(
    client: AuthenticatedSocket,
    chatId: string,
    messageId: string
): Promise<void> {
  if (!chatId || !messageId) {
    sendError(client, 'delete_message: chatId и messageId обязательны');
    return;
  }

  // Добавлен await для db.deleteMessage
  await db.deleteMessage(chatId, messageId);

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
// Сохраняет FCM-токен устройства в асинхронную БД для offline push
// ─────────────────────────────────────────────────────────────

// Функция стала async
async function handleSyncFcmToken(client: AuthenticatedSocket, token: string): Promise<void> {
  if (!token || token.length < 20) {
    sendError(client, 'sync_fcm_token: token невалиден или пуст');
    return;
  }

  // Добавлены await для db.upsertFcmToken
  await db.upsertFcmToken(client.user.userId, token);
  if (client.user.email && client.user.email !== client.user.userId) {
    await db.upsertFcmToken(client.user.email, token);
  }

  console.log(
      `[ChatController] FCM-токен синхронизирован для userId=${client.user.userId} / email=${client.user.email}: ` +
      `${token.slice(0, 20)}...`
  );
}

// ─────────────────────────────────────────────────────────────
// remove_fcm_token
// Удаляет FCM-токен устройства из БД при выходе из аккаунта (логауте)
// ─────────────────────────────────────────────────────────────

// Функция стала async
async function handleRemoveFcmToken(client: AuthenticatedSocket, token: string): Promise<void> {
  if (!token) {
    sendError(client, 'remove_fcm_token: token обязателен');
    return;
  }

  // Добавлены await для db.deleteFcmToken
  await db.deleteFcmToken(client.user.userId, token);
  if (client.user.email && client.user.email !== client.user.userId) {
    await db.deleteFcmToken(client.user.email, token);
  }

  console.log(
      `[ChatController] FCM-токен удалён при логауте для userId=${client.user.userId} / email=${client.user.email}: ` +
      `${token.slice(0, 20)}...`
  );
}

// ─────────────────────────────────────────────────────────────
// upsert_group_chat
// Сохраняет или обновляет данные метаинформации группового чата
// ─────────────────────────────────────────────────────────────

// Функция стала async
async function handleUpsertGroupChat(
    client: AuthenticatedSocket,
    chat: GroupChatDto
): Promise<void> {
  if (!chat || !chat.id) {
    sendError(client, 'upsert_group_chat: chat.id обязателен');
    return;
  }

  // Добавлен await для db.upsertGroupChat
  await db.upsertGroupChat(chat);

  console.log(
      `[ChatController] Групповой чат ${chat.id} ("${chat.title}") сохранён в БД ` +
      `пользователем ${client.user.userId}`
  );
}

// ─────────────────────────────────────────────────────────────
// typing
// Транслирует событие набора текста другим участникам прямого чата.
// Не персистируется в БД, поэтому остается синхронным.
// ─────────────────────────────────────────────────────────────

function handleTyping(
    client: AuthenticatedSocket,
    chatId: string,
    isTyping: boolean
): void {
  if (!chatId) {
    sendError(client, 'typing: chatId обязателен');
    return;
  }

  const senderId = client.user.userId.trim().toLowerCase();
  const topicId = chatTopicKey(chatId);
  const subscribers = getSubscribers(topicId);

  const outbound = {
    type: 'typing' as const,
    chatId,
    userId: senderId,
    isTyping,
  };

  for (const subscriber of subscribers) {
    // Не отправляем самому отправителю
    if (subscriber.user.userId.trim().toLowerCase() !== senderId) {
      sendToClient(subscriber, outbound);
    }
  }
}
