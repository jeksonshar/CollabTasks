# CollabTasks — WebSocket Chat Server

Автономный Node.js/TypeScript WebSocket-сервер для AWS Cognito режима приложения **CollabTasks**.  
Реализует полный контракт `ChatRemoteDataSource` через raw `ws` протокол — без Socket.io.

---

## Архитектура

```
chat-server/
├── src/
│   ├── server.ts                        # Точка входа: HTTP + raw ws.Server
│   ├── middleware/
│   │   └── authMiddleware.ts            # Валидация AWS Cognito JWT при handshake
│   ├── websocket/
│   │   ├── connectionManager.ts         # userId → sockets + heartbeat
│   │   └── subscriptionManager.ts       # topicId → subscribers (ручной pub/sub)
│   ├── controllers/
│   │   └── chatController.ts            # Обработчик всех 9 методов ChatRemoteDataSource
│   ├── services/
│   │   └── pushNotificationService.ts   # Firebase Admin FCM для offline-пользователей
│   ├── storage/
│   │   └── db.ts                        # SQLite (better-sqlite3) — замена Firestore
│   └── models/
│       └── types.ts                     # DTO и типы WS-событий
├── .env.example                         # Шаблон переменных окружения
├── package.json
├── tsconfig.json
└── README.md
```

---

## Требования

- **Node.js** v18+
- **npm** v9+
- AWS Cognito User Pool (для JWT-валидации)
- Firebase проект (для FCM push-уведомлений, опционально)

---

## Установка и настройка

### 1. Установите зависимости

```bash
cd chat-server
npm install
```

### 2. Настройте переменные окружения

```bash
cp .env.example .env
```

Заполните `.env`:

| Переменная | Описание | Пример |
|---|---|---|
| `COGNITO_USER_POOL_ID` | ID User Pool | `eu-west-1_AbcDeFgHi` |
| `COGNITO_CLIENT_ID` | ID App Client | `1a2b3c4d5e6f7g8h9i0j` |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | Путь к JSON ключу Firebase Admin | `./serviceAccountKey.json` |
| `PORT` | Порт сервера | `8080` |
| `HOST` | Хост для bind | `0.0.0.0` |
| `DB_PATH` | Путь к SQLite файлу | `./data/chat.db` |
| `PING_INTERVAL_MS` | Интервал heartbeat ping | `30000` |
| `PONG_TIMEOUT_MS` | Таймаут pong ответа | `10000` |

### 3. Firebase Service Account (для FCM)

1. Перейдите в [Firebase Console](https://console.firebase.google.com) → Project Settings → Service Accounts
2. Нажмите "Generate new private key" → скачайте JSON
3. Сохраните как `serviceAccountKey.json` в корне `chat-server/`

---

## Запуск

### Режим разработки (с hot-reload)

```bash
npm run dev
```

### Продакшн

```bash
npm run build
npm start
```

---

## WS Event Protocol

Все сообщения — JSON с обязательным полем `type`.

### Подключение

```
ws://host:port/?token=<cognito_access_jwt>
```

Или через заголовок `Authorization: Bearer <jwt>`.

### Входящие события (Client → Server)

#### `subscribe_topic` — подписаться на чат/группу

```json
{ "type": "subscribe_topic", "topicId": "chat:<chatId>" }
{ "type": "subscribe_topic", "topicId": "group:<groupId>" }
```

При успешной подписке сервер сразу отдаёт историю сообщений через `new_message` / `new_group_message`.

#### `unsubscribe_topic`

```json
{ "type": "unsubscribe_topic", "topicId": "chat:<chatId>" }
```

#### `send_message` — отправить сообщение в личный чат

```json
{
  "type": "send_message",
  "chatId": "uuid",
  "message": {
    "id": "uuid",
    "senderId": "cognito-sub",
    "senderName": "Иван Иванов",
    "text": "Привет!",
    "createdAtMillis": 1720000000000
  }
}
```

#### `send_group_message` — отправить сообщение в групповой чат

```json
{
  "type": "send_group_message",
  "groupId": "uuid",
  "message": { ... }
}
```

#### `get_chats`

```json
{ "type": "get_chats", "userId": "cognito-sub" }
```

#### `get_or_create_direct_chat`

```json
{ "type": "get_or_create_direct_chat", "targetUserId": "cognito-sub-2" }
```

#### `get_chat_by_id`

```json
{ "type": "get_chat_by_id", "chatId": "uuid" }
```

#### `get_group_chat_by_id`

```json
{ "type": "get_group_chat_by_id", "chatId": "uuid" }
```

#### `delete_message`

```json
{ "type": "delete_message", "chatId": "uuid", "messageId": "uuid" }
```

#### `sync_fcm_token` — сохранить FCM-токен устройства для offline push

```json
{ "type": "sync_fcm_token", "token": "<fcm_device_token>" }
```

> Необходимо вызывать при каждом входе в систему. Токен привязывается к `userId` из JWT.

---

### Исходящие события (Server → Client)

| Событие | Описание |
|---|---|
| `new_message` | Новое сообщение в личном чате |
| `new_group_message` | Новое сообщение в групповом чате |
| `chat_list` | Список чатов пользователя |
| `direct_chat_created` | ID созданного/найденного прямого чата |
| `chat_by_id` | Данные личного чата |
| `group_chat_by_id` | Данные группового чата |
| `message_deleted` | Сообщение удалено |
| `error` | Ошибка (с полем `message`) |

---

## FCM Push-уведомления

### Логика

1. При отправке сообщения сервер определяет список получателей
2. Проверяет, подключён ли каждый получатель через WS (`isUserOnline`)
3. Для **offline** получателей извлекает FCM-токены из SQLite (сохранённые через `sync_fcm_token`)
4. Отправляет FCM multicast через Firebase Admin SDK

### Payload (точно соответствует ожиданиям Flutter `ChatNotificationService`)

**Личный чат:**
```json
{
  "notification": { "title": "Иван Иванов", "body": "Привет!" },
  "data": {
    "chatId": "uuid",
    "type": "chat_message",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

**Групповой чат:**
```json
{
  "notification": { "title": "Участник", "body": "Сообщение" },
  "data": {
    "groupId": "uuid",
    "type": "group_chat_message",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

---

## Health Check

```
GET http://host:port/health
→ { "status": "ok", "timestamp": "2026-08-10T..." }
```

---

## Соответствие методам ChatRemoteDataSource

| Flutter метод | WS событие |
|---|---|
| `watchMessages(chatId)` | `subscribe_topic { topicId: "chat:<chatId>" }` → `new_message` |
| `sendMessage(chatId, msg)` | `send_message` |
| `watchGroupMessages(groupId)` | `subscribe_topic { topicId: "group:<groupId>" }` → `new_group_message` |
| `sendGroupMessage(groupId, msg)` | `send_group_message` |
| `getChats(userId)` | `get_chats` → `chat_list` |
| `getOrCreateDirectChat(targetId)` | `get_or_create_direct_chat` → `direct_chat_created` |
| `getChatById(chatId)` | `get_chat_by_id` → `chat_by_id` |
| `getGroupChatById(chatId)` | `get_group_chat_by_id` → `group_chat_by_id` |
| `deleteMessage(chatId, msgId)` | `delete_message` → `message_deleted` |

---

## Интеграция с Flutter (AWS Cognito режим)

В `AwsWsChatRemoteDataSource` (реализация `ChatRemoteDataSource` для AWS режима):

1. Получить Cognito access token через `Amplify.Auth.fetchAuthSession()`
2. Подключиться: `WebSocket('ws://host:8080/?token=$accessToken')`
3. Отправить `sync_fcm_token` с токеном из `FirebaseMessaging.instance.getToken()`
4. Использовать тот же API событий что описан выше
