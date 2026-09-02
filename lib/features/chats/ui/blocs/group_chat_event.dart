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

class SendGroupMessageEvent extends GroupChatEvent {
  final String groupChatId;
  final String textMessage;

  const SendGroupMessageEvent(this.groupChatId, this.textMessage);

  @override
  List<Object?> get props => [groupChatId, textMessage];
}

class LoadMoreGroupMessagesEvent extends GroupChatEvent {
  const LoadMoreGroupMessagesEvent();
}
