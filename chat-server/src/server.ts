// ============================================================
// src/server.ts
// Точка входа — HTTP-сервер + raw ws.Server
// Адаптировано для асинхронного PostgreSQL API (storage/db.ts)
// ============================================================

import 'dotenv/config';
import http from 'http';
import WebSocket, { WebSocketServer } from 'ws';

import { authenticateRequest } from './middleware/authMiddleware';
import {
  AuthenticatedSocket,
  addConnection,
  removeConnection,
  startHeartbeat,
  handlePong,
  broadcastUserStatus,
} from './websocket/connectionManager';
import { unsubscribeAll } from './websocket/subscriptionManager';
import { handleEvent } from './controllers/chatController';
import { initializeFirebase } from './services/pushNotificationService';
import { initDatabase, upsertLastSeen } from './storage/db'; // upsertLastSeen тепер async
import { InboundEvent } from './models/types';

// ─────────────────────────────────────────────────────────────
// Конфигурация (должна совпадать с данными в .env файле)
// ─────────────────────────────────────────────────────────────

// ВАЖНО: Render передает порт в env.PORT.
// Ваш код правильно читает его или использует 8080 как fallback.
const PORT = parseInt(process.env.PORT ?? '8080', 10);
const HOST = process.env.HOST ?? '0.0.0.0';

// ─────────────────────────────────────────────────────────────
// Основная async-функция запуска
// ─────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  // 1. Инициализируем PostgreSQL базу данных (Supabase)
  // Асинхронно проверяет подключение и наличие таблиц (на Шаге 1).
  await initDatabase();

  // 2. Firebase Admin SDK для FCM push-уведомлений
  // Читает JSON из FIREBASE_SERVICE_ACCOUNT_JSON на Render.
  initializeFirebase();

  // ─────────────────────────────────────────────────────────────
  // HTTP-сервер (нужен для WS и health-check endpoint)
  // ─────────────────────────────────────────────────────────────

  const httpServer = http.createServer((req, res) => {
    // Health-check endpoint для Render / Load Balancer / мониторинга
    // Render будет использовать этот URL для проверки работоспособности сервиса.
    if (req.url === '/health' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'ok', timestamp: new Date().toISOString() }));
      return;
    }

    // Все остальные HTTP-запросы — 404
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found. Connect via WebSocket.');
  });

  // ─────────────────────────────────────────────────────────────
  // WebSocket Server (raw ws — без Socket.io)
  // ─────────────────────────────────────────────────────────────

  const wss = new WebSocketServer({
    server: httpServer,
    // handleProtocols: разрешаем подключение через Sec-WebSocket-Protocol
    // Flutter может передавать JWT-токен как subprotocol
    handleProtocols: (protocols: Set<string>) => {
      if (protocols.has('chat')) return 'chat';
      // Принимаем любой — токен будет извлечён в authMiddleware из query/header
      if (protocols.size > 0) return Array.from(protocols)[0];
      return false;
    },
  });

  // ─────────────────────────────────────────────────────────────
  // Обработка новых WS-подключений
  // ─────────────────────────────────────────────────────────────

  wss.on('connection', (ws: WebSocket, req: http.IncomingMessage) => {
    console.log(
        `[Server] Новое WS-подключение от ${req.socket.remoteAddress ?? 'unknown'}`
    );

    let client: AuthenticatedSocket | null = null;
    let isClosed = false;
    const messageBuffer: WebSocket.RawData[] = [];

    // ── 1. Немедленно регистрируем heartbeat, ошибки и закрытие ──
    ws.on('pong', () => {
      handlePong(ws);
    });

    ws.on('error', (err: Error) => {
      console.error('[Server] Ошибка сокета:', err.message);
    });

    ws.on('close', async (code: number, reason: Buffer) => {
      isClosed = true;
      if (!client) {
        console.log(`[Server] Неаутентифицированный WS закрыт: code=${code}`);
        return;
      }

      const { user } = client;
      console.log(
          `[Server] WS закрыт: userId=${user.userId} ` +
          `code=${code} reason=${reason.toString() || '—'}`
      );

      unsubscribeAll(client);

      // Сохраняем lastSeen в PostgreSQL и рассылаем offline-статус
      const lastSeenMs = Date.now();
      const dbPromises: Promise<void>[] = [];
      dbPromises.push(upsertLastSeen(user.userId, lastSeenMs));
      if (user.email) {
        dbPromises.push(upsertLastSeen(user.email, lastSeenMs));
      }

      try {
        await Promise.all(dbPromises);
      } catch (err) {
        console.error(`[Server] Ошибка сохранения lastSeen для userId=${user.userId}:`, err);
      }

      removeConnection(ws);

      // Рассылаем offline-статус в фоне
      void broadcastUserStatus(user, 'offline', lastSeenMs).catch((err) => {
        console.error(`[Server] Ошибка рассылки offline-статуса для userId=${user.userId}:`, err);
      });
    });

    // ── 2. Функция обработки входящего сообщения ──
    const processMessage = async (rawData: WebSocket.RawData) => {
      if (!client) return;

      let event: InboundEvent;
      try {
        const text = rawData.toString('utf8');
        event = JSON.parse(text) as InboundEvent;
      } catch {
        console.warn(`[Server] Невалидный JSON от userId=${client.user.userId}`);
        ws.send(JSON.stringify({ type: 'error', message: 'Невалидный JSON формат' }));
        return;
      }

      // Валидируем наличие поля type
      if (!event || typeof event.type !== 'string') {
        ws.send(
            JSON.stringify({ type: 'error', message: 'Поле "type" обязательно в каждом событии' })
        );
        return;
      }

      try {
        await handleEvent(client, event);
      } catch (err) {
        console.error(
            `[Server] Необработанная ошибка при обработке события от userId=${client.user.userId}:`,
            err
        );
        ws.send(
            JSON.stringify({
              type: 'error',
              message: 'Внутренняя ошибка сервера. Попробуйте позже.',
            })
        );
      }
    };

    // ── 3. Немедленно вешаем слушатель сообщений (буферизует до завершения аутентификации) ──
    ws.on('message', async (rawData: WebSocket.RawData) => {
      if (!client) {
        messageBuffer.push(rawData);
        return;
      }
      await processMessage(rawData);
    });

    // ── 4. Асинхронная аутентификация и регистрация клиента ──
    (async () => {
      let user;
      try {
        user = await authenticateRequest(req);
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        console.warn(`[Server] Отклонено подключение: ${message}`);
        ws.send(JSON.stringify({ type: 'error', message }));
        ws.close(1008, 'Unauthorized');
        return;
      }

      if (isClosed || ws.readyState !== WebSocket.OPEN) {
        return;
      }

      client = addConnection(ws, user);
      console.log(`[Server] ✅ Авторизован: userId=${user.userId} email=${user.email}`);

      // Рассылаем online-статус в фоне, не блокируя очередь сообщений
      void broadcastUserStatus(user, 'online').catch((err) => {
        console.error(`[Server] Ошибка рассылки online-статуса для userId=${user.userId}:`, err);
      });

      // Обрабатываем накопившиеся во время рукопожатия сообщения
      while (messageBuffer.length > 0) {
        const bufferedData = messageBuffer.shift();
        if (bufferedData) {
          await processMessage(bufferedData);
        }
      }
    })().catch((err) => {
      console.error('[Server] Ошибка во время инициализации подключения:', err);
      ws.close(1011, 'Internal error during authentication');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Запуск HTTP сервера
  // ─────────────────────────────────────────────────────────────

  // Render назначит порт, бэкенд его прочитает. adb reverse больше не нужен.
  await new Promise<void>((resolve) => {
    httpServer.listen(PORT, HOST, () => {
      console.log(`\n🚀 CollabTasks Chat Server запущен`);
      console.log(`   HTTP/WS: ws://${HOST}:${PORT}`);
      console.log(`   Health:  http://${HOST}:${PORT}/health`);
      console.log(`   Режим:   ${process.env.NODE_ENV ?? 'development'}\n`);
      // Heartbeat важен на Render (убирает молчаливые разрывы load balancer'ом)
      startHeartbeat();
      resolve();
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Graceful shutdown
  // ─────────────────────────────────────────────────────────────
  // Render посылает SIGTERM при остановке/редеплое сервиса.

  function shutdown(signal: string): void {
    console.log(`\n[Server] Получен сигнал ${signal}, завершаем работу...`);

    wss.close(() => console.log('[Server] WebSocket сервер закрыт.'));

    httpServer.close(() => {
      console.log('[Server] HTTP сервер закрыт.');
      // Закрытие пула PostgreSQL здесь не требуется, т.к. процесс завершается.
      process.exit(0);
    });

    setTimeout(() => {
      console.error('[Server] Принудительное завершение.');
      process.exit(1);
    }, 10_000);
  }

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

// ─────────────────────────────────────────────────────────────
// Глобальные обработчики ошибок
// ─────────────────────────────────────────────────────────────

process.on('uncaughtException', (err) => {
  console.error('[Server] Необработанное исключение:', err);
});

process.on('unhandledRejection', (reason) => {
  console.error('[Server] Необработанный rejection Promise:', reason);
});

// ─────────────────────────────────────────────────────────────
// Запуск
// ─────────────────────────────────────────────────────────────

main().catch((err) => {
  console.error('[Server] Критическая ошибка при запуске:', err);
  process.exit(1);
});