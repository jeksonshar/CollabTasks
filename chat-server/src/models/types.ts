// ============================================================
// src/models/types.ts
// DTO-определения и типы WS-событий для CollabTasks Chat Server
// Контракт строго соответствует Flutter ChatRemoteDataSource
// ============================================================

// ─────────────────────────────────────────────────────────────
// Базовые DTO (зеркало Flutter MessageDto / ChatDto / GroupChatDto)
// ─────────────────────────────────────────────────────────────

/** Тип чата (direct — личный, group — групповой) */
export type ChatType = 'direct' | 'group';

/** DTO одного сообщения (зеркало Flutter MessageDto) */
export interface MessageDto {
  id: string;
  senderId: string;
  senderName: string;
  text: string;
  createdAtMillis: number;
}

/** DTO личного чата (зеркало Flutter ChatDto) */
export interface ChatDto {
  id: string;
  type: ChatType;
  participantIds: string[];
  lastMessage: string;
  updatedAtMillis: number;
}

/** DTO группового чата (зеркало Flutter GroupChatDto) */
export interface GroupChatDto {
  id: string;
  participantUserIds: string[];
  participantEmails: string[];
  title: string;
  description: string;
  updatedAtMillis: number;
}

// ─────────────────────────────────────────────────────────────
// Аутентифицированный клиент
// ─────────────────────────────────────────────────────────────

/** Информация об аутентифицированном пользователе, извлечённая из Cognito JWT */
export interface AuthenticatedUser {
  userId: string;   // sub (UUID Cognito)
  email: string;
  name: string;
}

// ─────────────────────────────────────────────────────────────
// Входящие WS-события (Client → Server)
// ─────────────────────────────────────────────────────────────

export interface SubscribeTopicEvent {
  type: 'subscribe_topic';
  topicId: string;
}

export interface UnsubscribeTopicEvent {
  type: 'unsubscribe_topic';
  topicId: string;
}

export interface SendMessageEvent {
  type: 'send_message';
  chatId: string;
  message: MessageDto;
}

export interface SendGroupMessageEvent {
  type: 'send_group_message';
  groupId: string;
  message: MessageDto;
}

export interface GetChatsEvent {
  type: 'get_chats';
  userId: string;
}

export interface GetOrCreateDirectChatEvent {
  type: 'get_or_create_direct_chat';
  targetUserId: string;
}

export interface GetChatByIdEvent {
  type: 'get_chat_by_id';
  chatId: string;
}

export interface GetGroupChatByIdEvent {
  type: 'get_group_chat_by_id';
  chatId: string;
}

export interface DeleteMessageEvent {
  type: 'delete_message';
  chatId: string;
  messageId: string;
}

export interface SyncFcmTokenEvent {
  type: 'sync_fcm_token';
  token: string;
}

export interface RemoveFcmTokenEvent {
  type: 'remove_fcm_token';
  token: string;
}

export interface UpsertGroupChatEvent {
  type: 'upsert_group_chat';
  chat: GroupChatDto;
}

export interface LoadMoreMessagesEvent {
  type: 'load_more_messages';
  topicId: string;
  beforeCreatedAtMillis: number;
  beforeId: string;
  limit?: number;
}

/**
 * Клиент уведомляет сервер о том, что пользователь печатает / перестал печатать.
 * Сервер транслирует событие другим участникам прямого чата.
 */
export interface TypingEvent {
  type: 'typing';
  /** ID прямого чата, в котором происходит набор текста */
  chatId: string;
  isTyping: boolean;
}

/** Объединение всех входящих событий */
export type InboundEvent =
  | SubscribeTopicEvent
  | UnsubscribeTopicEvent
  | SendMessageEvent
  | SendGroupMessageEvent
  | GetChatsEvent
  | GetOrCreateDirectChatEvent
  | GetChatByIdEvent
  | GetGroupChatByIdEvent
  | DeleteMessageEvent
  | SyncFcmTokenEvent
  | RemoveFcmTokenEvent
  | UpsertGroupChatEvent
  | LoadMoreMessagesEvent
  | TypingEvent;

// ─────────────────────────────────────────────────────────────
// Исходящие WS-события (Server → Client)
// ─────────────────────────────────────────────────────────────

export interface NewMessageOutbound {
  type: 'new_message';
  chatId: string;
  message: MessageDto;
}

export interface NewGroupMessageOutbound {
  type: 'new_group_message';
  groupId: string;
  message: MessageDto;
}

export interface ChatListOutbound {
  type: 'chat_list';
  chats: ChatDto[];
}

export interface DirectChatCreatedOutbound {
  type: 'direct_chat_created';
  chatId: string;
}

export interface ChatByIdOutbound {
  type: 'chat_by_id';
  chat: ChatDto | null;
}

export interface GroupChatByIdOutbound {
  type: 'group_chat_by_id';
  chat: GroupChatDto | null;
}

export interface MessageDeletedOutbound {
  type: 'message_deleted';
  chatId: string;
  messageId: string;
}

export interface ErrorOutbound {
  type: 'error';
  message: string;
}

/**
 * Сервер → клиенты: статус присутствия пользователя изменился.
 * `lastSeenMillis` передаётся только при переходе в offline.
 */
export interface UserStatusChangedOutbound {
  type: 'user_status_changed';
  /** Нормализованный userId (trim + toLowerCase) */
  userId: string;
  status: 'online' | 'offline';
  lastSeenMillis?: number;
}

/**
 * Сервер → клиенты: пользователь начал / прекратил набор текста в прямом чате.
 * Не персистируется в БД.
 */
export interface TypingOutbound {
  type: 'typing';
  chatId: string;
  /** Нормализованный userId набирающего пользователя */
  userId: string;
  isTyping: boolean;
}

export interface MessagesHistoryOutbound {
  type: 'messages_history';
  chatId: string;
  messages: MessageDto[];
  hasMore: boolean;
}

export interface GroupMessagesHistoryOutbound {
  type: 'group_messages_history';
  groupId: string;
  messages: MessageDto[];
  hasMore: boolean;
}

export interface MessagesPageOutbound {
  type: 'messages_page';
  topicId: string;
  messages: MessageDto[];
  hasMore: boolean;
}

/** Объединение всех исходящих событий */
export type OutboundEvent =
  | NewMessageOutbound
  | NewGroupMessageOutbound
  | MessagesHistoryOutbound
  | GroupMessagesHistoryOutbound
  | MessagesPageOutbound
  | ChatListOutbound
  | DirectChatCreatedOutbound
  | ChatByIdOutbound
  | GroupChatByIdOutbound
  | MessageDeletedOutbound
  | ErrorOutbound
  | UserStatusChangedOutbound
  | TypingOutbound;
