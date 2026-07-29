import 'package:collab_tasks/features/chats/domain/models/message_entity.dart';
import 'package:equatable/equatable.dart';

abstract class GroupChatState extends Equatable {
  const GroupChatState();

  @override
  List<Object?> get props => [];
}

class GroupChatInitial extends GroupChatState {
  const GroupChatInitial();
}

class GroupChatLoading extends GroupChatState {
  const GroupChatLoading();
}

class GroupChatSuccess extends GroupChatState {
  final List<MessageEntity> messages;
  final String groupChatTitle;
  final String groupChatDescription;
  final String currentUserId;

  const GroupChatSuccess({
    required this.messages,
    required this.groupChatTitle,
    required this.groupChatDescription,
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [messages, groupChatTitle, groupChatDescription, currentUserId];
}

class GroupChatError extends GroupChatState {
  final String message;

  const GroupChatError(this.message);

  @override
  List<Object?> get props => [message];
}
