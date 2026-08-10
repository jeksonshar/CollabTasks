// ============================================================
// src/websocket/subscriptionManager.ts
// Ручное управление подписками топиков (chatId / groupId → clients)
// ============================================================

import WebSocket from 'ws';
import { AuthenticatedSocket } from './connectionManager';

// ─────────────────────────────────────────────────────────────
// Состояние
// ─────────────────────────────────────────────────────────────

/**
 * Карта topicId → Set<AuthenticatedSocket>
 *
 * topicId для личного чата:  "chat:<chatId>"
 * topicId для группового:    "group:<groupId>"
 */
const topicToSubscribers = new Map<string, Set<AuthenticatedSocket>>();

/** Обратная карта ws → Set<topicId> для cleanup при disconnect */
const socketToTopics = new Map<WebSocket, Set<string>>();

// ─────────────────────────────────────────────────────────────
// Вспомогательные функции создания ключей
// ─────────────────────────────────────────────────────────────

export const chatTopicKey = (chatId: string): string => `chat:${chatId}`;
export const groupTopicKey = (groupId: string): string => `group:${groupId}`;

// ─────────────────────────────────────────────────────────────
// API
// ─────────────────────────────────────────────────────────────

/**
 * Подписывает клиента на топик.
 * Идемпотентно — повторная подписка на тот же топик безопасна.
 */
export function subscribe(client: AuthenticatedSocket, topicId: string): void {
  // Добавляем клиента к топику
  let subscribers = topicToSubscribers.get(topicId);
  if (!subscribers) {
    subscribers = new Set();
    topicToSubscribers.set(topicId, subscribers);
  }
  subscribers.add(client);

  // Обновляем обратную карту
  let topics = socketToTopics.get(client.ws);
  if (!topics) {
    topics = new Set();
    socketToTopics.set(client.ws, topics);
  }
  topics.add(topicId);

  console.log(
    `[SubscriptionManager] userId=${client.user.userId} → подписан на "${topicId}" ` +
    `(всего в топике: ${subscribers.size})`
  );
}

/**
 * Отписывает клиента от топика.
 */
export function unsubscribe(client: AuthenticatedSocket, topicId: string): void {
  const subscribers = topicToSubscribers.get(topicId);
  if (subscribers) {
    subscribers.delete(client);
    if (subscribers.size === 0) {
      topicToSubscribers.delete(topicId);
    }
  }

  const topics = socketToTopics.get(client.ws);
  if (topics) {
    topics.delete(topicId);
  }

  console.log(
    `[SubscriptionManager] userId=${client.user.userId} → отписан от "${topicId}"`
  );
}

/**
 * Удаляет все подписки клиента (вызывается при disconnect).
 */
export function unsubscribeAll(client: AuthenticatedSocket): void {
  const topics = socketToTopics.get(client.ws);
  if (!topics) return;

  for (const topicId of topics) {
    const subscribers = topicToSubscribers.get(topicId);
    if (subscribers) {
      subscribers.delete(client);
      if (subscribers.size === 0) {
        topicToSubscribers.delete(topicId);
      }
    }
  }

  socketToTopics.delete(client.ws);

  console.log(
    `[SubscriptionManager] userId=${client.user.userId} → все подписки очищены`
  );
}

/**
 * Возвращает всех подписчиков топика.
 */
export function getSubscribers(topicId: string): AuthenticatedSocket[] {
  const subs = topicToSubscribers.get(topicId);
  return subs ? Array.from(subs) : [];
}

/**
 * Проверяет, подписан ли клиент на данный топик.
 */
export function isSubscribed(client: AuthenticatedSocket, topicId: string): boolean {
  return topicToSubscribers.get(topicId)?.has(client) ?? false;
}

/**
 * Возвращает список всех топиков, на которые подписан клиент.
 */
export function getClientTopics(client: AuthenticatedSocket): string[] {
  const topics = socketToTopics.get(client.ws);
  return topics ? Array.from(topics) : [];
}
