import 'package:collab_tasks/features/chats/domain/models/message_entity.dart';
import 'package:equatable/equatable.dart';

abstract class GroupChatEvent extends Equatable {
  const GroupChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadGroupMessagesEvent extends GroupChatEvent {
  final String groupChatId;

  const LoadGroupMessagesEvent(this.groupChatId);

  @override
  List<Object?> get props => [groupChatId];
}

class OnGroupMessagesUpdatedEvent extends GroupChatEvent {
  final List<MessageEntity> messages;
  final String groupChatTitle;
  final String groupChatDescription;

  const OnGroupMessagesUpdatedEvent(this.messages, this.groupChatTitle, this.groupChatDescription);

  @override
  List<Object?> get props => [messages, groupChatTitle, groupChatDescription];
}

class SendGroupMessageEvent extends GroupChatEvent {
  final String groupChatId;
  final String textMessage;

  const SendGroupMessageEvent(this.groupChatId, this.textMessage);

  @override
  List<Object?> get props => [groupChatId, textMessage];
}
