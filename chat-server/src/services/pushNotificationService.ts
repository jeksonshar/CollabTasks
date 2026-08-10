// ============================================================
// src/services/pushNotificationService.ts
// Firebase Admin FCM — push-уведомления для offline-пользователей
// Полностью зеркалирует логику Cloud Functions index.ts
// ============================================================

import * as admin from 'firebase-admin';
import * as db from '../storage/db';
import { isUserOnline } from '../websocket/connectionManager';

// ─────────────────────────────────────────────────────────────
// Инициализация Firebase Admin SDK
// ─────────────────────────────────────────────────────────────

let firebaseInitialized = false;

export function initializeFirebase(): void {
  if (firebaseInitialized) return;

  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

  if (!serviceAccountPath) {
    console.warn(
      '[FCM] FIREBASE_SERVICE_ACCOUNT_PATH не задан — push-уведомления отключены.'
    );
    return;
  }

  try {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const serviceAccount = require(require('path').resolve(serviceAccountPath)) as admin.ServiceAccount;
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    firebaseInitialized = true;
    console.log('[FCM] Firebase Admin SDK инициализирован.');
  } catch (err) {
    console.error('[FCM] Ошибка инициализации Firebase Admin SDK:', err);
  }
}

// ─────────────────────────────────────────────────────────────
// Вспомогательные функции
// ─────────────────────────────────────────────────────────────

/**
 * Формирует multicast payload для ЛИЧНОГО чата.
 * Структура data-полей точно совпадает с ожиданиями Flutter ChatNotificationService:
 *   data.chatId, data.type = "chat_message", data.click_action
 */
function buildDirectChatPayload(
  tokens: string[],
  senderName: string,
  text: string,
  chatId: string
): admin.messaging.MulticastMessage {
  return {
    tokens,
    notification: {
      title: senderName,
      body: text || 'Изображение или файл',
    },
    data: {
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
      chatId,
      type: 'chat_message',
    },
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        channelId: 'chats_messages_channel',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        },
      },
    },
  };
}

/**
 * Формирует multicast payload для ГРУППОВОГО чата.
 * Структура data-полей:
 *   data.groupId, data.type = "group_chat_message", data.click_action
 */
function buildGroupChatPayload(
  tokens: string[],
  senderName: string,
  text: string,
  groupId: string
): admin.messaging.MulticastMessage {
  return {
    tokens,
    notification: {
      title: senderName,
      body: text || 'Изображение или файл',
    },
    data: {
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
      groupId,
      type: 'group_chat_message',
    },
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        channelId: 'chats_messages_channel',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        },
      },
    },
  };
}

/**
 * Отправляет multicast FCM с логированием и удалением невалидных токенов.
 */
async function sendMulticast(
  payload: admin.messaging.MulticastMessage,
  recipientUserIds: string[]
): Promise<void> {
  if (!firebaseInitialized) {
    console.warn('[FCM] Firebase не инициализирован — пуш не отправлен.');
    return;
  }

  if (payload.tokens.length === 0) return;

  try {
    const response = await admin.messaging().sendEachForMulticast(payload);
    console.log(
      `[FCM] Отправлено: ${response.successCount}/${payload.tokens.length} успешно`
    );

    // Удаляем невалидные/истёкшие токены из локальной БД
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const failedToken = payload.tokens[idx];
        const errorCode = resp.error?.code;
        if (
          errorCode === 'messaging/invalid-registration-token' ||
          errorCode === 'messaging/registration-token-not-registered'
        ) {
          // Ищем userId для этого токена и удаляем из БД
          for (const userId of recipientUserIds) {
            db.deleteFcmToken(userId, failedToken);
          }
          console.log(`[FCM] Удалён невалидный токен: ${failedToken.slice(0, 20)}...`);
        }
      }
    });
  } catch (err) {
    console.error('[FCM] Ошибка отправки push-уведомления:', err);
  }
}

// ─────────────────────────────────────────────────────────────
// Публичный API
// ─────────────────────────────────────────────────────────────

/**
 * Отправляет FCM push-уведомление получателям ЛИЧНОГО чата.
 *
 * Логика (зеркало index.ts onNewMessageSent):
 * 1. Получаем список participantIds чата
 * 2. Исключаем senderId
 * 3. Для каждого offline-получателя берём FCM-токены из локальной БД
 * 4. Отправляем multicast FCM
 */
export async function sendDirectChatPushNotification(
  chatId: string,
  senderId: string,
  senderName: string,
  text: string,
  participantIds: string[]
): Promise<void> {
  const recipientIds = participantIds.filter(
    (id) => id.toLowerCase() !== senderId.toLowerCase()
  );

  if (recipientIds.length === 0) return;

  // Собираем токены только offline-получателей
  const tokens: string[] = [];
  const offlineRecipientIds: string[] = [];

  for (const recipientId of recipientIds) {
    if (isUserOnline(recipientId)) {
      console.log(
        `[FCM] Пропущен online-получатель: ${recipientId} — получает через WS`
      );
      continue;
    }

    offlineRecipientIds.push(recipientId);
    const recipientTokens = db.getFcmTokens(recipientId);
    tokens.push(...recipientTokens);
  }

  if (tokens.length === 0) {
    console.log(`[FCM] Нет FCM-токенов для offline-получателей чата ${chatId}`);
    return;
  }

  const uniqueTokens = [...new Set(tokens)];
  const payload = buildDirectChatPayload(uniqueTokens, senderName, text, chatId);
  await sendMulticast(payload, offlineRecipientIds);
}

/**
 * Отправляет FCM push-уведомление участникам ГРУППОВОГО чата.
 *
 * Логика (зеркало index.ts onNewGroupMessageSent):
 * 1. Получаем participantUserIds из GroupChatDto
 * 2. Исключаем senderId (по userId и email)
 * 3. Для каждого offline-получателя берём FCM-токены из локальной БД
 * 4. Отправляем multicast FCM
 */
export async function sendGroupChatPushNotification(
  groupId: string,
  senderId: string,
  senderName: string,
  text: string,
  participantUserIds: string[]
): Promise<void> {
  const senderIdLower = senderId.toLowerCase();

  // Фильтруем отправителя (точная логика из index.ts)
  const filteredRecipients = participantUserIds.filter((id) => {
    const cleanId = String(id).trim();
    if (!cleanId) return false;
    return cleanId.toLowerCase() !== senderIdLower;
  });

  const uniqueRecipients = [...new Set(filteredRecipients)];

  if (uniqueRecipients.length === 0) {
    console.log('[FCM] Все получатели отфильтрованы как отправитель (группа)');
    return;
  }

  // Собираем токены только offline-получателей
  const tokens: string[] = [];
  const offlineRecipientIds: string[] = [];

  for (const recipientId of uniqueRecipients) {
    if (isUserOnline(recipientId)) {
      console.log(
        `[FCM] Пропущен online-участник группы: ${recipientId} — получает через WS`
      );
      continue;
    }

    offlineRecipientIds.push(recipientId);
    const recipientTokens = db.getFcmTokens(recipientId);
    tokens.push(...recipientTokens);
  }

  if (tokens.length === 0) {
    console.log(
      `[FCM] Нет FCM-токенов для offline-участников группы ${groupId}. ` +
      `Искали по: ${uniqueRecipients.join(', ')}`
    );
    return;
  }

  const uniqueTokens = [...new Set(tokens)];
  const payload = buildGroupChatPayload(uniqueTokens, senderName, text, groupId);
  await sendMulticast(payload, offlineRecipientIds);
}
