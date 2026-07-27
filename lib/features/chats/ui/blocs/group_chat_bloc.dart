import 'dart:async';

import 'package:collab_tasks/features/chats/domain/models/message_entity.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/send_group_message_use_case.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/watch_group_messages_use_case.dart';
import 'package:collab_tasks/features/chats/ui/blocs/group_chat_event.dart';
import 'package:collab_tasks/features/chats/ui/blocs/group_chat_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GroupChatBloc extends Bloc<GroupChatEvent, GroupChatState> {
  final WatchGroupMessagesUseCase _watchGroupMessagesUseCase;
  final SendGroupMessageUseCase _sendGroupMessageUseCase;

  StreamSubscription<List<MessageEntity>>? _messagesSubscription;

  GroupChatBloc({
    required WatchGroupMessagesUseCase watchGroupMessagesUseCase,
    required SendGroupMessageUseCase sendGroupMessageUseCase,
  }) : _watchGroupMessagesUseCase = watchGroupMessagesUseCase,
       _sendGroupMessageUseCase = sendGroupMessageUseCase,
       super(const GroupChatInitial()) {
    on<LoadGroupMessagesEvent>(_onLoadGroupMessages);
    on<SendGroupMessageEvent>(_onSendGroupMessage);
    on<_OnGroupMessagesUpdated>(_onGroupMessagesUpdated);
    on<_OnGroupMessagesFailed>(_onGroupMessagesFailed);
  }

  Future<void> _onLoadGroupMessages(
    LoadGroupMessagesEvent event,
    Emitter<GroupChatState> emit,
  ) async {
    emit(const GroupChatLoading());
    await _messagesSubscription?.cancel();

    try {
      _messagesSubscription = _watchGroupMessagesUseCase(event.groupChatId).listen(
        (messages) => add(_OnGroupMessagesUpdated(messages)),
        onError: (Object error) => add(_OnGroupMessagesFailed(error.toString())),
      );
    } catch (e) {
      add(_OnGroupMessagesFailed(e.toString()));
    }
  }

  void _onGroupMessagesUpdated(_OnGroupMessagesUpdated event, Emitter<GroupChatState> emit) {
    emit(GroupChatSuccess(event.messages));
  }

  void _onGroupMessagesFailed(_OnGroupMessagesFailed event, Emitter<GroupChatState> emit) {
    emit(GroupChatError(event.error));
  }

  Future<void> _onSendGroupMessage(
    SendGroupMessageEvent event,
    Emitter<GroupChatState> emit,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final senderId = currentUser?.email ?? currentUser?.uid ?? '';

      await _sendGroupMessageUseCase(
        groupId: event.groupChatId,
        content: event.textMessage,
        senderId: senderId,
      );
    } catch (e) {
      emit(GroupChatError(e.toString()));
    }
  }

  @override
  Future<void> close() async {
    await _messagesSubscription?.cancel();
    return super.close();
  }
}

class _OnGroupMessagesUpdated extends GroupChatEvent {
  final List<MessageEntity> messages;

  const _OnGroupMessagesUpdated(this.messages);

  @override
  List<Object?> get props => [messages];
}

class _OnGroupMessagesFailed extends GroupChatEvent {
  final String error;

  const _OnGroupMessagesFailed(this.error);

  @override
  List<Object?> get props => [error];
}
