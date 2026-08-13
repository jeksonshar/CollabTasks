// ============================================================
// src/websocket/connectionManager.ts
// Управление аутентифицированными WS-соединениями и heartbeat
// ============================================================

import WebSocket from 'ws';
import { AuthenticatedUser, OutboundEvent } from '../models/types';

// ─────────────────────────────────────────────────────────────
// Типы
// ─────────────────────────────────────────────────────────────

/** Расширенный клиент с метаданными аутентификации и heartbeat */
export interface AuthenticatedSocket {
  ws: WebSocket;
  user: AuthenticatedUser;
  /** true — ожидаем pong от клиента */
  isAlive: boolean;
  connectedAt: Date;
}

// ─────────────────────────────────────────────────────────────
// Состояние менеджера
// ─────────────────────────────────────────────────────────────

/**
 * Карта userId → список активных сокетов.
 * Один пользователь может быть подключён с нескольких устройств одновременно.
 */
const connectionsByUserId = new Map<string, Set<AuthenticatedSocket>>();

/** Обратная карта ws → AuthenticatedSocket для быстрого lookup при событиях */
const socketToClient = new Map<WebSocket, AuthenticatedSocket>();

let heartbeatTimer: ReturnType<typeof setInterval> | null = null;

// ─────────────────────────────────────────────────────────────
// Управление соединениями
// ─────────────────────────────────────────────────────────────

/** Регистрирует новое аутентифицированное соединение */
export function addConnection(ws: WebSocket, user: AuthenticatedUser): AuthenticatedSocket {
  const client: AuthenticatedSocket = {
    ws,
    user,
    isAlive: true,
    connectedAt: new Date(),
  };

  // Добавляем в карту userId → sockets
  let userSockets = connectionsByUserId.get(user.userId);
  if (!userSockets) {
    userSockets = new Set();
    connectionsByUserId.set(user.userId, userSockets);
  }
  userSockets.add(client);

  // Добавляем в обратную карту
  socketToClient.set(ws, client);

  console.log(
    `[ConnectionManager] Подключён: userId=${user.userId} email=${user.email} ` +
    `(всего сессий у пользователя: ${userSockets.size})`
  );

  return client;
}

/** Удаляет соединение при disconnect / ошибке */
export function removeConnection(ws: WebSocket): void {
  const client = socketToClient.get(ws);
  if (!client) return;

  socketToClient.delete(ws);

  const userSockets = connectionsByUserId.get(client.user.userId);
  if (userSockets) {
    userSockets.delete(client);
    if (userSockets.size === 0) {
      connectionsByUserId.delete(client.user.userId);
    }
  }

  console.log(
    `[ConnectionManager] Отключён: userId=${client.user.userId} email=${client.user.email}`
  );
}

/** Получает AuthenticatedSocket по объекту WebSocket */
export function getClientBySocket(ws: WebSocket): AuthenticatedSocket | undefined {
  return socketToClient.get(ws);
}

/** Получает все активные сокеты для данного userId или email */
export function getSocketsByUserId(id: string): AuthenticatedSocket[] {
  if (!id) return [];
  const target = id.toLowerCase();
  const result: AuthenticatedSocket[] = [];
  for (const client of socketToClient.values()) {
    if (
      client.user.userId.toLowerCase() === target ||
      client.user.email.toLowerCase() === target
    ) {
      result.push(client);
    }
  }
  return result;
}

/** Проверяет, подключён ли пользователь хотя бы через один сокет (по userId или email) */
export function isUserOnline(id: string): boolean {
  return getSocketsByUserId(id).length > 0;
}

/** Возвращает список всех онлайн-пользователей */
export function getOnlineUserIds(): string[] {
  return Array.from(connectionsByUserId.keys());
}

// ─────────────────────────────────────────────────────────────
// Отправка сообщений
// ─────────────────────────────────────────────────────────────

/**
 * Отправляет событие конкретному клиенту.
 * Ошибки отправки логируются и не пробрасываются — клиент мог закрыть соединение.
 */
export function sendToClient(client: AuthenticatedSocket, event: OutboundEvent): void {
  if (client.ws.readyState !== WebSocket.OPEN) return;
  try {
    client.ws.send(JSON.stringify(event));
  } catch (err) {
    console.error(
      `[ConnectionManager] Ошибка отправки клиенту userId=${client.user.userId}:`,
      err
    );
  }
}

/**
 * Отправляет событие всем активным сессиям пользователя.
 */
export function sendToUser(userId: string, event: OutboundEvent): void {
  const clients = getSocketsByUserId(userId);
  for (const client of clients) {
    sendToClient(client, event);
  }
}

/**
 * Отправляет сообщение об ошибке конкретному клиенту.
 */
export function sendError(client: AuthenticatedSocket, message: string): void {
  sendToClient(client, { type: 'error', message });
}

// ─────────────────────────────────────────────────────────────
// Heartbeat (ping/pong)
// ─────────────────────────────────────────────────────────────

const PING_INTERVAL_MS = parseInt(process.env.PING_INTERVAL_MS ?? '30000', 10);
const PONG_TIMEOUT_MS = parseInt(process.env.PONG_TIMEOUT_MS ?? '10000', 10);

/**
 * Запускает периодический heartbeat.
 * Клиентам, не ответившим на ping в течение PONG_TIMEOUT_MS, соединение закрывается.
 */
export function startHeartbeat(): void {
  if (heartbeatTimer) return;

  heartbeatTimer = setInterval(() => {
    const now = Date.now();

    for (const [ws, client] of socketToClient) {
      if (!client.isAlive) {
        // Клиент не ответил на предыдущий ping — закрываем соединение
        console.warn(
          `[Heartbeat] Нет ответа от userId=${client.user.userId}, закрываем соединение`
        );
        ws.terminate();
        continue;
      }

      // Помечаем как "ожидаем pong"
      client.isAlive = false;

      try {
        ws.ping();
      } catch {
        ws.terminate();
      }
    }

    void now; // используем переменную (устраняем предупреждение TS)
  }, PING_INTERVAL_MS);

  console.log(
    `[Heartbeat] Запущен: интервал=${PING_INTERVAL_MS}мс, таймаут=${PONG_TIMEOUT_MS}мс`
  );
}

/**
 * Обрабатывает pong от клиента — помечаем соединение как живое.
 */
export function handlePong(ws: WebSocket): void {
  const client = socketToClient.get(ws);
  if (client) {
    client.isAlive = true;
  }
}

/** Останавливает heartbeat */
export function stopHeartbeat(): void {
  if (heartbeatTimer) {
    clearInterval(heartbeatTimer);
    heartbeatTimer = null;
  }
}
