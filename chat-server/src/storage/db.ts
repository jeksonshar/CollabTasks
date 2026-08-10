// ============================================================
// src/storage/db.ts
// Лёгкая локальная база данных на SQLite через sql.js (pure WASM)
// sql.js работает без нативной компиляции на любой платформе
// ============================================================

import initSqlJs, { Database, SqlValue } from 'sql.js';
import path from 'path';
import fs from 'fs';
import { ChatDto, GroupChatDto, MessageDto } from '../models/types';

// ─────────────────────────────────────────────────────────────
// Инициализация
// ─────────────────────────────────────────────────────────────

const dbPath = path.resolve(process.env.DB_PATH ?? './data/chat.db');

// Создаём директорию если нет
const dbDir = path.dirname(dbPath);
if (!fs.existsSync(dbDir)) {
  fs.mkdirSync(dbDir, { recursive: true });
}

/** Глобальный экземпляр БД (синхронный API sql.js) */
let db: Database;

/** Периодическое сохранение БД на диск (раз в 5 секунд при наличии изменений) */
let _isDirty = false;

function markDirty(): void {
  _isDirty = true;
}

function persistDb(): void {
  if (!_isDirty) return;
  const data = db.export();
  fs.writeFileSync(dbPath, Buffer.from(data));
  _isDirty = false;
}

// ─────────────────────────────────────────────────────────────
// Асинхронная инициализация (вызывается один раз при старте)
// ─────────────────────────────────────────────────────────────

export async function initDatabase(): Promise<void> {
  const SQL = await initSqlJs();

  // Загружаем существующую БД или создаём новую
  if (fs.existsSync(dbPath)) {
    const fileBuffer = fs.readFileSync(dbPath);
    db = new SQL.Database(fileBuffer);
  } else {
    db = new SQL.Database();
  }

  // Создаём схему
  db.run(`
    CREATE TABLE IF NOT EXISTS chats (
      id             TEXT PRIMARY KEY,
      type           TEXT NOT NULL DEFAULT 'direct',
      participant_ids TEXT NOT NULL,
      last_message   TEXT NOT NULL DEFAULT '',
      updated_at_ms  INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS group_chats (
      id                  TEXT PRIMARY KEY,
      participant_user_ids TEXT NOT NULL,
      participant_emails   TEXT NOT NULL,
      title               TEXT NOT NULL DEFAULT '',
      description         TEXT NOT NULL DEFAULT '',
      updated_at_ms       INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS messages (
      id              TEXT NOT NULL,
      chat_id         TEXT NOT NULL,
      sender_id       TEXT NOT NULL,
      sender_name     TEXT NOT NULL DEFAULT '',
      text            TEXT NOT NULL DEFAULT '',
      created_at_ms   INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (id, chat_id)
    );

    CREATE TABLE IF NOT EXISTS group_messages (
      id              TEXT NOT NULL,
      group_id        TEXT NOT NULL,
      sender_id       TEXT NOT NULL,
      sender_name     TEXT NOT NULL DEFAULT '',
      text            TEXT NOT NULL DEFAULT '',
      created_at_ms   INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (id, group_id)
    );

    CREATE TABLE IF NOT EXISTS fcm_tokens (
      user_id   TEXT NOT NULL,
      token     TEXT NOT NULL,
      PRIMARY KEY (user_id, token)
    );

    CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages (chat_id, created_at_ms);
    CREATE INDEX IF NOT EXISTS idx_group_messages_group_id ON group_messages (group_id, created_at_ms);
    CREATE INDEX IF NOT EXISTS idx_fcm_user ON fcm_tokens (user_id);
  `);

  // Сохраняем БД на диск каждые 5 секунд при изменениях
  setInterval(persistDb, 5000);

  // Сохраняем при завершении процесса
  process.on('exit', () => persistDb());
  process.on('SIGTERM', () => persistDb());
  process.on('SIGINT', () => persistDb());

  console.log(`[DB] SQLite инициализирована: ${dbPath}`);
}

// ─────────────────────────────────────────────────────────────
// Вспомогательная функция: getDb() с guard
// ─────────────────────────────────────────────────────────────

function getDb(): Database {
  if (!db) {
    throw new Error('[DB] База данных не инициализирована. Вызовите initDatabase() перед использованием.');
  }
  return db;
}

// ─────────────────────────────────────────────────────────────
// Маппинг строк БД → DTO
// ─────────────────────────────────────────────────────────────

type AnyRow = Record<string, unknown>;

function rowToChat(row: AnyRow): ChatDto {
  return {
    id: row['id'] as string,
    type: row['type'] as 'direct' | 'group',
    participantIds: JSON.parse(row['participant_ids'] as string) as string[],
    lastMessage: row['last_message'] as string,
    updatedAtMillis: row['updated_at_ms'] as number,
  };
}

function rowToGroupChat(row: AnyRow): GroupChatDto {
  return {
    id: row['id'] as string,
    participantUserIds: JSON.parse(row['participant_user_ids'] as string) as string[],
    participantEmails: JSON.parse(row['participant_emails'] as string) as string[],
    title: row['title'] as string,
    description: row['description'] as string,
    updatedAtMillis: row['updated_at_ms'] as number,
  };
}

function rowToMessage(row: AnyRow): MessageDto {
  return {
    id: row['id'] as string,
    senderId: row['sender_id'] as string,
    senderName: row['sender_name'] as string,
    text: row['text'] as string,
    createdAtMillis: row['created_at_ms'] as number,
  };
}

/** Выполняет SELECT и возвращает массив объектов */
function queryAll(sql: string, params: SqlValue[] = []): AnyRow[] {
  const stmt = getDb().prepare(sql);
  const results: AnyRow[] = [];
  stmt.bind(params);
  while (stmt.step()) {
    results.push(stmt.getAsObject() as AnyRow);
  }
  stmt.free();
  return results;
}

/** Выполняет SELECT и возвращает первую строку или undefined */
function queryOne(sql: string, params: SqlValue[] = []): AnyRow | undefined {
  const rows = queryAll(sql, params);
  return rows[0];
}

/** Выполняет INSERT / UPDATE / DELETE */
function execute(sql: string, params: SqlValue[] = []): void {
  getDb().run(sql, params);
  markDirty();
}

// ─────────────────────────────────────────────────────────────
// Публичный API — Chats
// ─────────────────────────────────────────────────────────────

export function getChatById(chatId: string): ChatDto | null {
  const row = queryOne('SELECT * FROM chats WHERE id = ?', [chatId]);
  return row ? rowToChat(row) : null;
}

export function getChatsByUserId(userId: string): ChatDto[] {
  // Ищем чаты где participant_ids JSON-массив содержит userId
  // sql.js не поддерживает json_each — используем LIKE для простоты
  const all = queryAll("SELECT * FROM chats WHERE participant_ids LIKE ?", [`%"${userId}"%`]);
  // Дополнительная точная проверка
  return all
    .filter((row) => {
      const ids = JSON.parse(row['participant_ids'] as string) as string[];
      return ids.includes(userId);
    })
    .map(rowToChat);
}

export function upsertChat(chat: ChatDto): void {
  execute(
    `INSERT OR REPLACE INTO chats (id, type, participant_ids, last_message, updated_at_ms)
     VALUES (?, ?, ?, ?, ?)`,
    [chat.id, chat.type, JSON.stringify(chat.participantIds), chat.lastMessage, chat.updatedAtMillis]
  );
}

export function updateChatLastMessage(chatId: string, lastMessage: string, updatedAtMs: number): void {
  execute(
    'UPDATE chats SET last_message = ?, updated_at_ms = ? WHERE id = ?',
    [lastMessage, updatedAtMs, chatId]
  );
}

export function findDirectChat(userId: string, targetUserId: string): ChatDto | null {
  // Получаем все direct-чаты где участвует userId
  const candidates = queryAll(
    "SELECT * FROM chats WHERE type = 'direct' AND participant_ids LIKE ?",
    [`%"${userId}"%`]
  );
  for (const row of candidates) {
    const participants = JSON.parse(row['participant_ids'] as string) as string[];
    if (participants.length === 2 && participants.includes(targetUserId) && participants.includes(userId)) {
      return rowToChat(row);
    }
  }
  return null;
}

// ─────────────────────────────────────────────────────────────
// Messages
// ─────────────────────────────────────────────────────────────

export function getMessages(chatId: string): MessageDto[] {
  const rows = queryAll(
    'SELECT * FROM messages WHERE chat_id = ? ORDER BY created_at_ms DESC',
    [chatId]
  );
  return rows.map(rowToMessage);
}

export function insertMessage(chatId: string, message: MessageDto): void {
  execute(
    `INSERT OR IGNORE INTO messages (id, chat_id, sender_id, sender_name, text, created_at_ms)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [message.id, chatId, message.senderId, message.senderName, message.text, message.createdAtMillis]
  );
}

export function deleteMessage(chatId: string, messageId: string): void {
  execute('DELETE FROM messages WHERE id = ? AND chat_id = ?', [messageId, chatId]);
}

// ─────────────────────────────────────────────────────────────
// Group Chats
// ─────────────────────────────────────────────────────────────

export function getGroupChatById(groupId: string): GroupChatDto | null {
  const row = queryOne('SELECT * FROM group_chats WHERE id = ?', [groupId]);
  return row ? rowToGroupChat(row) : null;
}

export function upsertGroupChat(chat: GroupChatDto): void {
  execute(
    `INSERT OR REPLACE INTO group_chats
       (id, participant_user_ids, participant_emails, title, description, updated_at_ms)
     VALUES (?, ?, ?, ?, ?, ?)`,
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
// Group Messages
// ─────────────────────────────────────────────────────────────

export function getGroupMessages(groupId: string): MessageDto[] {
  const rows = queryAll(
    'SELECT * FROM group_messages WHERE group_id = ? ORDER BY created_at_ms DESC',
    [groupId]
  );
  return rows.map(rowToMessage);
}

export function insertGroupMessage(groupId: string, message: MessageDto): void {
  execute(
    `INSERT OR IGNORE INTO group_messages (id, group_id, sender_id, sender_name, text, created_at_ms)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [message.id, groupId, message.senderId, message.senderName, message.text, message.createdAtMillis]
  );
}

// ─────────────────────────────────────────────────────────────
// FCM Tokens
// ─────────────────────────────────────────────────────────────

export function upsertFcmToken(userId: string, token: string): void {
  execute('INSERT OR REPLACE INTO fcm_tokens (user_id, token) VALUES (?, ?)', [userId, token]);
}

export function getFcmTokens(userId: string): string[] {
  const rows = queryAll('SELECT token FROM fcm_tokens WHERE user_id = ?', [userId]);
  return rows.map((r) => r['token'] as string);
}

export function deleteFcmToken(userId: string, token: string): void {
  execute('DELETE FROM fcm_tokens WHERE user_id = ? AND token = ?', [userId, token]);
}
