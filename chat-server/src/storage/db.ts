// ============================================================
// src/storage/db.ts
// Persistence-слой бэкенда, использующий PostgreSQL
// Взаимодействие осуществляется через библиотеку-драйвер 'pg'
// ============================================================

import { Pool, QueryResultRow } from 'pg'; // Основные импорты из pg
import { ChatDto, GroupChatDto, MessageDto } from '../models/types';

// ─────────────────────────────────────────────────────────────
// Инициализация Пула Подключений (Pool)
// ─────────────────────────────────────────────────────────────

// Строка подключения берется из переменной окружения в .env
const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error('[DB] Ошибка: Переменная окружения DATABASE_URL не задана в .env');
}

/** * Глобальный экземпляр пула подключений.
 * Инициализируется один раз при старте приложения.
 */
const pool = new Pool({
  connectionString,
  // Настройки SSL обязательны для Supabase и большинства облачных хостингов
  ssl: {
    // Разрешаем самоподписанные сертификаты (стандарт для бесплатных тарифов)
    rejectUnauthorized: false
  },
  // Максимальное количество одновременных подключений в пуле (настройте под тариф)
  max: 10,
  // Тайм-аут подключения (мс)
  connectionTimeoutMillis: 5000,
  // Тайм-аут простоя подключения перед закрытием (мс)
  idleTimeoutMillis: 30000,
});

/**
 * Асинхронная инициализация.
 * Проверяет подключение к БД при старте сервера.
 */
export async function initDatabase(): Promise<void> {
  try {
    // Пытаемся взять подключение из пула и выполнить тестовый запрос
    const client = await pool.connect();
    console.log('[DB] Успешное подключение к PostgreSQL базе данных.');

    // (Опционально) Здесь можно выполнить тестовый запрос для проверки таблиц:
    // const res = await client.query('SELECT NOW()');
    // console.log('[DB] Время сервера БД:', res.rows[0]);

    // Всегда возвращаем клиент обратно в пул после использования!
    client.release();

  } catch (error) {
    console.error('[DB] Критическая ошибка при инициализации подключения к PostgreSQL:', error);
    // Останавливаем приложение, если нет подключения к БД
    process.exit(1);
  }
}

// ─────────────────────────────────────────────────────────────
// Вспомогательные асинхронные функции запросов
// ─────────────────────────────────────────────────────────────

/** Выполняет любой SQL запрос и возвращает сырой массив строк (QueryResultRow) */
async function queryAll<T extends QueryResultRow>(sql: string, params: any[] = []): Promise<T[]> {
  const result = await pool.query<T>(sql, params);
  return result.rows;
}

/** Выполняет SELECT и возвращает первую строку или undefined */
async function queryOne<T extends QueryResultRow>(sql: string, params: any[] = []): Promise<T | undefined> {
  const rows = await queryAll<T>(sql, params);
  return rows[0];
}

/** Выполняет INSERT / UPDATE / DELETE (не возвращает строки, но подтверждает выполнение) */
async function execute(sql: string, params: any[] = []): Promise<void> {
  await pool.query(sql, params);
  // Persist логика (markDirty) здесь больше не нужна
}

// ─────────────────────────────────────────────────────────────
// Маппинг строк БД → DTO
// ─────────────────────────────────────────────────────────────

/** Утилита для безопасного парсинга JSON строк из БД (SQLite хранил массивы как JSON-строки) */
function safeJsonParse<T>(jsonString: string, defaultValue: T): T {
  if (!jsonString) return defaultValue;
  try {
    return JSON.parse(jsonString) as T;
  } catch (e) {
    console.error(`[DB] Ошибка парсинга JSON: ${jsonString}`, e);
    return defaultValue;
  }
}

// Типизация строк, возвращаемых pg (pg возвращает объект Record<string, any>)
interface AnyRow extends QueryResultRow {
  id: string;
  [key: string]: any;
}

function rowToChat(row: AnyRow): ChatDto {
  return {
    id: row.id,
    type: row.type as 'direct' | 'group',
    // В PostgreSQL мы храним participant_ids как TEXT (JSON-строку), как и в SQLite
    participantIds: safeJsonParse<string[]>(row.participant_ids, []),
    lastMessage: row.last_message ?? '',
    updatedAtMillis: Number(row.updated_at_ms) ?? 0, // Приводим bigint/integer к числу
  };
}

function rowToGroupChat(row: AnyRow): GroupChatDto {
  return {
    id: row.id,
    participantUserIds: safeJsonParse<string[]>(row.participant_user_ids, []),
    participantEmails: safeJsonParse<string[]>(row.participant_emails, []),
    title: row.title ?? '',
    description: row.description ?? '',
    updatedAtMillis: Number(row.updated_at_ms) ?? 0,
  };
}

function rowToMessage(row: AnyRow): MessageDto {
  return {
    id: row.id,
    senderId: row.sender_id,
    senderName: row.sender_name ?? '',
    text: row.text ?? '',
    createdAtMillis: Number(row.created_at_ms) ?? 0,
  };
}

// ─────────────────────────────────────────────────────────────
// Публичный API — Chats (ВСЕ ФУНКЦИИ ASYNC)
// ─────────────────────────────────────────────────────────────

export async function getChatById(chatId: string): Promise<ChatDto | null> {
  const row = await queryOne<AnyRow>('SELECT * FROM chats WHERE id = $1', [chatId]);
  return row ? rowToChat(row) : null;
}

export async function getChatsByUserId(userIdentifiers: string | string[]): Promise<ChatDto[]> {
  const idsToMatch = (Array.isArray(userIdentifiers) ? userIdentifiers : [userIdentifiers])
      .filter(Boolean)
      .map((id) => id.toLowerCase());

  // Получаем все чаты
  const allRows = await queryAll<AnyRow>("SELECT * FROM chats");

  // Фильтруем на стороне бэкенда (как и раньше, т.к. participant_ids — JSON)
  return allRows
      .filter((row) => {
        const participants = safeJsonParse<string[]>(row.participant_ids, []);
        const lowerParticipants = participants.map((id) => id.toLowerCase());
        return lowerParticipants.some((id) => idsToMatch.includes(id));
      })
      .map(rowToChat);
}

export async function upsertChat(chat: ChatDto): Promise<void> {
  // PostgreSQL синтаксис для "INSERT OR REPLACE" — это ON CONFLICT
  const sql = `
    INSERT INTO chats (id, type, participant_ids, last_message, updated_at_ms)
    VALUES ($1, $2, $3, $4, $5)
    ON CONFLICT (id) DO UPDATE 
    SET type = EXCLUDED.type, 
        participant_ids = EXCLUDED.participant_ids, 
        last_message = EXCLUDED.last_message, 
        updated_at_ms = EXCLUDED.updated_at_ms;
  `;
  await execute(
      sql,
      [chat.id, chat.type, JSON.stringify(chat.participantIds), chat.lastMessage, chat.updatedAtMillis]
  );
}

export async function updateChatLastMessage(chatId: string, lastMessage: string, updatedAtMs: number): Promise<void> {
  await execute(
      'UPDATE chats SET last_message = $1, updated_at_ms = $2 WHERE id = $3',
      [lastMessage, updatedAtMs, chatId]
  );
}

export async function findDirectChat(
    userAIdentifiers: string | string[],
    userBIdentifiers: string | string[]
): Promise<ChatDto | null> {
  const idsA = (Array.isArray(userAIdentifiers) ? userAIdentifiers : [userAIdentifiers])
      .filter(Boolean)
      .map((id) => id.toLowerCase());

  const idsB = (Array.isArray(userBIdentifiers) ? userBIdentifiers : [userBIdentifiers])
      .filter(Boolean)
      .map((id) => id.toLowerCase());

  // Получаем все direct чаты
  const candidates = await queryAll<AnyRow>("SELECT * FROM chats WHERE type = 'direct'");

  // Фильтруем на стороне бэкенда
  for (const row of candidates) {
    const participants = safeJsonParse<string[]>(row.participant_ids, []);
    const lowerParticipants = participants.map((id) => id.toLowerCase());

    if (lowerParticipants.length === 2) {
      const matchesA = lowerParticipants.some((p) => idsA.includes(p));
      const matchesB = lowerParticipants.some((p) => idsB.includes(p));
      if (matchesA && matchesB) {
        return rowToChat(row);
      }
    }
  }
  return null;
}

// ─────────────────────────────────────────────────────────────
// Messages (ВСЕ ФУНКЦИИ ASYNC)
// ─────────────────────────────────────────────────────────────

export async function getMessages(chatId: string): Promise<MessageDto[]> {
  const rows = await queryAll<AnyRow>(
      'SELECT * FROM messages WHERE chat_id = $1 ORDER BY created_at_ms DESC, id DESC',
      [chatId]
  );
  return rows.map(rowToMessage);
}

export async function insertMessage(chatId: string, message: MessageDto): Promise<void> {
  // PostgreSQL ON CONFLICT DO NOTHING — это аналог INSERT OR IGNORE
  const sql = `
    INSERT INTO messages (id, chat_id, sender_id, sender_name, text, created_at_ms)
    VALUES ($1, $2, $3, $4, $5, $6)
    ON CONFLICT (id, chat_id) DO NOTHING;
  `;
  await execute(
      sql,
      [message.id, chatId, message.senderId, message.senderName, message.text, message.createdAtMillis]
  );
}

export async function deleteMessage(chatId: string, messageId: string): Promise<void> {
  await execute('DELETE FROM messages WHERE id = $1 AND chat_id = $2', [messageId, chatId]);
}

// ─────────────────────────────────────────────────────────────
// Group Chats (ВСЕ ФУНКЦИИ ASYNC)
// ─────────────────────────────────────────────────────────────

export async function getGroupChatById(groupId: string): Promise<GroupChatDto | null> {
  const row = await queryOne<AnyRow>('SELECT * FROM group_chats WHERE id = $1', [groupId]);
  return row ? rowToGroupChat(row) : null;
}

export async function upsertGroupChat(chat: GroupChatDto): Promise<void> {
  const sql = `
    INSERT INTO group_chats (id, participant_user_ids, participant_emails, title, description, updated_at_ms)
    VALUES ($1, $2, $3, $4, $5, $6)
    ON CONFLICT (id) DO UPDATE 
    SET participant_user_ids = EXCLUDED.participant_user_ids,
        participant_emails = EXCLUDED.participant_emails,
        title = EXCLUDED.title,
        description = EXCLUDED.description,
        updated_at_ms = EXCLUDED.updated_at_ms;
  `;
  await execute(
      sql,
      [
        chat.id,
        JSON.stringify(chat.participantUserIds),
        JSON.stringify(chat.participantEmails),
        chat.title,
        chat.description,
        chat.updatedAtMillis,
      ]
  );
}

// ─────────────────────────────────────────────────────────────
// Group Messages (ВСЕ ФУНКЦИИ ASYNC)
// ─────────────────────────────────────────────────────────────

export async function getGroupMessages(groupId: string): Promise<MessageDto[]> {
  const rows = await queryAll<AnyRow>(
      'SELECT * FROM group_messages WHERE group_id = $1 ORDER BY created_at_ms DESC, id DESC',
      [groupId]
  );
  return rows.map(rowToMessage);
}

export async function insertGroupMessage(groupId: string, message: MessageDto): Promise<void> {
  const sql = `
    INSERT INTO group_messages (id, group_id, sender_id, sender_name, text, created_at_ms)
    VALUES ($1, $2, $3, $4, $5, $6)
    ON CONFLICT (id, group_id) DO NOTHING;
  `;
  await execute(
      sql,
      [message.id, groupId, message.senderId, message.senderName, message.text, message.createdAtMillis]
  );
}

// ─────────────────────────────────────────────────────────────
// FCM Tokens (ВСЕ ФУНКЦИИ ASYNC)
// ─────────────────────────────────────────────────────────────

export async function upsertFcmToken(userId: string, token: string): Promise<void> {
  const sql = `
    INSERT INTO fcm_tokens (user_id, token)
    VALUES ($1, $2)
    ON CONFLICT (user_id, token) DO NOTHING; -- REPLACE не нужен, т.к. PK составной
  `;
  await execute(sql, [userId, token]);
}

export async function getFcmTokens(userIdentifiers: string | string[]): Promise<string[]> {
  const ids = (Array.isArray(userIdentifiers) ? userIdentifiers : [userIdentifiers])
      .filter(Boolean)
      .map((id) => id.toLowerCase());

  if (ids.length === 0) return [];

  // Фильтрация токенов (как и раньше, т.к. filterUserId на стороне бэкенда)
  const allRows = await queryAll<{ user_id: string, token: string }>('SELECT user_id, token FROM fcm_tokens');

  const matchedTokens: string[] = [];
  for (const row of allRows) {
    const rowUserId = row.user_id.toLowerCase();
    if (ids.includes(rowUserId)) {
      matchedTokens.push(row.token);
    }
  }
  return [...new Set(matchedTokens)];
}

export async function deleteFcmToken(userId: string, token: string): Promise<void> {
  await execute('DELETE FROM fcm_tokens WHERE user_id = $1 AND token = $2', [userId, token]);
}

// ─────────────────────────────────────────────────────────────
// User Last Seen (ВСЕ ФУНКЦИИ ASYNC)
// ─────────────────────────────────────────────────────────────

export async function upsertLastSeen(userId: string, lastSeenMs: number): Promise<void> {
  const normalized = userId.trim().toLowerCase();
  const sql = `
    INSERT INTO user_last_seen (user_id, last_seen_ms)
    VALUES ($1, $2)
    ON CONFLICT (user_id) DO UPDATE 
    SET last_seen_ms = EXCLUDED.last_seen_ms;
  `;
  await execute(sql, [normalized, lastSeenMs]);
}

export async function getLastSeen(userId: string): Promise<number> {
  const normalized = userId.trim().toLowerCase();
  const row = await queryOne<{ last_seen_ms: any }>('SELECT last_seen_ms FROM user_last_seen WHERE user_id = $1', [normalized]);
  return row ? Number(row.last_seen_ms) : 0;
}
