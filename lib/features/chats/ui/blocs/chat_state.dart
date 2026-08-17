import 'package:collab_tasks/features/chats/domain/models/message_entity.dart';
import 'package:collab_tasks/features/chats/domain/models/user_status_entity.dart';
import 'package:equatable/equatable.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  final List<MessageEntity> messages;
  final String opponentEmail;
  final String currentUserId;
  final UserStatusEntity? opponentStatus;
  final bool isOpponentTyping;

  const ChatLoaded({
    required this.messages,
    required this.opponentEmail,
    required this.currentUserId,
    this.opponentStatus,
    this.isOpponentTyping = false,
  });

  ChatLoaded copyWith({
    List<MessageEntity>? messages,
    String? opponentEmail,
    String? currentUserId,
    UserStatusEntity? opponentStatus,
    bool? isOpponentTyping,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      opponentEmail: opponentEmail ?? this.opponentEmail,
      currentUserId: currentUserId ?? this.currentUserId,
      opponentStatus: opponentStatus ?? this.opponentStatus,
      isOpponentTyping: isOpponentTyping ?? this.isOpponentTyping,
    );
  }

  @override
  List<Object?> get props => [
    messages,
    opponentEmail,
    currentUserId,
    opponentStatus,
    isOpponentTyping,
  ];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
