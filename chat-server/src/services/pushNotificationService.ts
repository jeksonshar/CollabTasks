// ============================================================
// src/services/pushNotificationService.ts
// Firebase Admin FCM — push-уведомления для offline-пользователей
// Адаптировано для деплоя на Render (чтение JSON из env)
// И взаимодействия с асинхронным PostgreSQL API (storage/db.ts)
// ============================================================

import * as admin from 'firebase-admin';
import * as db from '../storage/db';

// ─────────────────────────────────────────────────────────────
// Инициализация Firebase Admin SDK
// ─────────────────────────────────────────────────────────────

let firebaseInitialized = false;

export function initializeFirebase(): void {
  if (firebaseInitialized) return;

  // 1. Сначала пытаемся прочитать JSON-строку из env (для деплоя на Render)
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;

  if (serviceAccountJson) {
    try {
      // Парсим JSON строку в объект
      const serviceAccount = JSON.parse(serviceAccountJson) as admin.ServiceAccount;
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      firebaseInitialized = true;
      console.log('[FCM] Firebase Admin SDK инициализирован через JSON-строку из env.');
      return; // Успех, выходим
    } catch (err) {
      console.error('[FCM] Ошибка парсинга FIREBASE_SERVICE_ACCOUNT_JSON:', err);
      // Не выходим, пробуем старый метод (вдруг мы локально)
    }
  }

  // 2. Если строки нет, пробуем старый метод с путем к ФАЙЛУ (для локальной разработки)
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

  if (!serviceAccountPath) {
    console.warn(
        '[FCM] Секреты Firebase не найдены (ни JSON-строка, ни путь к файлу) — push-уведомления отключены.'
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
    console.log(`[FCM] Firebase Admin SDK инициализирован через файл: ${serviceAccountPath}`);
  } catch (err) {
    console.error('[FCM] Ошибка инициализации Firebase Admin SDK через файл:', err);
  }
}

// ─────────────────────────────────────────────────────────────
// Вспомогательные функции
// ─────────────────────────────────────────────────────────────

/** * Формирует multicast payload для ЛИЧНОГО чата.
 * Структура data-полей точно совпадает с ожиданиями Flutter ChatNotificationService:
 * data.chatId, data.type = "chat_message", data.click_action
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
 * data.groupId, data.type = "group_chat_message", data.click_action
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

/** * Отправляет multicast FCM с логированием и удалением невалидных токенов.
 * ЭТА ФУНКЦИЯ ТЕПЕРЬ ОБРАБАТЫВАЕТ АСИНХРОННОЕ УДАЛЕНИЕ ТОКЕНОВ
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

    // Удаляем невалидные/истёкшие токены из асинхронной PostgreSQL БД
    // Используем Promise.all для параллельного удаления
    const deletionPromises: Promise<void>[] = [];

    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const failedToken = payload.tokens[idx];
        const errorCode = resp.error?.code;
        if (
            errorCode === 'messaging/invalid-registration-token' ||
            errorCode === 'messaging/registration-token-not-registered'
        ) {
          // Ищем userId для этого токена и добавляем Promise удаления в массив
          for (const userId of recipientUserIds) {
            // !!! ВАЖНО: db.deleteFcmToken теперь async, добавляем Promise !!!
            deletionPromises.push(db.deleteFcmToken(userId, failedToken));
          }
          console.log(`[FCM] Планируется удаление невалидного токена: ${failedToken.slice(0, 20)}...`);
        }
      }
    });

    // Ожидаем завершения всех операций удаления
    if (deletionPromises.length > 0) {
      await Promise.all(deletionPromises);
      console.log(`[FCM] ✅ Успешно удалено ${deletionPromises.length} невалидных токенов из PostgreSQL.`);
    }

  } catch (err) {
    console.error('[FCM] Ошибка отправки multicast push-уведомления:', err);
  }
}

// ─────────────────────────────────────────────────────────────
// Публичный API
// ─────────────────────────────────────────────────────────────

/** * Отправляет FCM push-уведомление получателям ЛИЧНОГО чата.
 * ФУНКЦИЯ ОСТАЕТСЯ ASYNC, ДОБАВЛЕНЫ AWAIT ДЛЯ ОБРАЩЕНИЯ К БД
 */
export async function sendDirectChatPushNotification(
    chatId: string,
    senderId: string,
    senderName: string,
    text: string,
    participantIds: string[]
): Promise<void> {
  const senderIdLower = senderId.toLowerCase();
  const recipientIds = participantIds.filter(
      (id) => String(id).trim().toLowerCase() !== senderIdLower
  );

  if (recipientIds.length === 0) return;

  // !!! ВАЖНО: db.getFcmTokens теперь async, добавляем await !!!
  const tokens = await db.getFcmTokens(recipientIds);

  if (tokens.length === 0) {
    console.log(
        `[FCM] Нет FCM-токенов для получателей чата ${chatId} ` +
        `(искали по: ${recipientIds.join(', ')})`
    );
    return;
  }

  const uniqueTokens = [...new Set(tokens)];
  const payload = buildDirectChatPayload(uniqueTokens, senderName, text, chatId);
  // Вызов sendMulticast уже асинхронный и с await
  await sendMulticast(payload, recipientIds);
}

/** * Отправляет FCM push-уведомление участникам ГРУППОВОГО чата.
 * ФУНКЦИЯ ОСТАЕТСЯ ASYNC, ДОБАВЛЕНЫ AWAIT ДЛЯ ОБРАЩЕНИЯ К БД
 */
export async function sendGroupChatPushNotification(
    groupId: string,
    senderId: string,
    senderName: string,
    text: string,
    participantUserIds: string[]
): Promise<void> {
  const senderIdLower = senderId.toLowerCase();

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

  // !!! ВАЖНО: db.getFcmTokens теперь async, добавляем await !!!
  const tokens = await db.getFcmTokens(uniqueRecipients);

  if (tokens.length === 0) {
    console.log(
        `[FCM] Нет FCM-токенов для участников группы ${groupId}. ` +
        `Искали по: ${uniqueRecipients.join(', ')}`
    );
    return;
  }

  const uniqueTokens = [...new Set(tokens)];
  const payload = buildGroupChatPayload(uniqueTokens, senderName, text, groupId);
  // Вызов sendMulticast уже асинхронный и с await
  await sendMulticast(payload, uniqueRecipients);
}