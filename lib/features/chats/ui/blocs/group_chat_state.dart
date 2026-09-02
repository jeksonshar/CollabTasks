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
  final bool hasMore;
  final bool isLoadingMore;

  const GroupChatSuccess({
    required this.messages,
    required this.groupChatTitle,
    required this.groupChatDescription,
    required this.currentUserId,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  GroupChatSuccess copyWith({
    List<MessageEntity>? messages,
    String? groupChatTitle,
    String? groupChatDescription,
    String? currentUserId,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return GroupChatSuccess(
      messages: messages ?? this.messages,
      groupChatTitle: groupChatTitle ?? this.groupChatTitle,
      groupChatDescription: groupChatDescription ?? this.groupChatDescription,
      currentUserId: currentUserId ?? this.currentUserId,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    messages,
    groupChatTitle,
    groupChatDescription,
    currentUserId,
    hasMore,
    isLoadingMore,
  ];
}

class GroupChatError extends GroupChatState {
  final String message;

  const GroupChatError(this.message);

  @override
  List<Object?> get props => [message];
}
