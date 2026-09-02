import 'package:collab_tasks/features/chats/domain/models/message_entity.dart';
import 'package:collab_tasks/features/chats/domain/models/typing_status_entity.dart';
import 'package:collab_tasks/features/chats/domain/models/user_status_entity.dart';
import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadMessages extends ChatEvent {
  final String chatId;

  const LoadMessages(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class SendMessageEvent extends ChatEvent {
  final String chatId;
  final String text;

  const SendMessageEvent(this.chatId, this.text);

  @override
  List<Object?> get props => [chatId, text];
}

class DeleteMessageEvent extends ChatEvent {
  final String chatId;
  final String messageId;

  const DeleteMessageEvent(this.chatId, this.messageId);

  @override
  List<Object?> get props => [chatId, messageId];
}

/// Событие отправки локального статуса набора текста.
class SendTypingEvent extends ChatEvent {
  final String chatId;
  final bool isTyping;

  const SendTypingEvent(this.chatId, this.isTyping);

  @override
  List<Object?> get props => [chatId, isTyping];
}

/// Внутреннее событие обновления списка сообщений.
class MessagesUpdated extends ChatEvent {
  final List<MessageEntity> messages;

  const MessagesUpdated(this.messages);

  @override
  List<Object?> get props => [messages];
}

/// Внутреннее событие обновления статуса собеседника (онлайн/офлайн).
class UserStatusUpdated extends ChatEvent {
  final UserStatusEntity userStatus;

  const UserStatusUpdated(this.userStatus);

  @override
  List<Object?> get props => [userStatus];
}

/// Внутреннее событие обновления статуса набора текста в чате.
class TypingStatusUpdated extends ChatEvent {
  final TypingStatusEntity typingStatus;

  const TypingStatusUpdated(this.typingStatus);

  @override
  List<Object?> get props => [typingStatus];
}

/// Событие подгрузки следующей страницы более старых сообщений.
class LoadMoreMessages extends ChatEvent {
  const LoadMoreMessages();
}
