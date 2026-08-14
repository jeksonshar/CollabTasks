import 'dart:async';

import 'package:collab_tasks/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:collab_tasks/features/chats/domain/models/message_entity.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/get_group_chat_use_case.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/send_group_message_use_case.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/watch_group_messages_use_case.dart';
import 'package:collab_tasks/features/chats/ui/blocs/group_chat_event.dart';
import 'package:collab_tasks/features/chats/ui/blocs/group_chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GroupChatBloc extends Bloc<GroupChatEvent, GroupChatState> {
  final WatchGroupMessagesUseCase _watchGroupMessagesUseCase;
  final SendGroupMessageUseCase _sendGroupMessageUseCase;
  final GetGroupChatUseCase _getGroupChatUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  GroupChatBloc({
    required WatchGroupMessagesUseCase watchGroupMessagesUseCase,
    required SendGroupMessageUseCase sendGroupMessageUseCase,
    required GetGroupChatUseCase getGroupChatUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  }) : _watchGroupMessagesUseCase = watchGroupMessagesUseCase,
       _sendGroupMessageUseCase = sendGroupMessageUseCase,
       _getGroupChatUseCase = getGroupChatUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       super(const GroupChatInitial()) {
    on<LoadGroupMessagesEvent>(_onLoadGroupMessages);
    on<SendGroupMessageEvent>(_onSendGroupMessage);
  }

  Future<void> _onLoadGroupMessages(
    LoadGroupMessagesEvent event,
    Emitter<GroupChatState> emit,
  ) async {
    emit(const GroupChatLoading());

    try {
      final currentUser = await _getCurrentUserUseCase();
      final currentUserId = currentUser?.email ?? currentUser?.id ?? '';

      final chat = await _getGroupChatUseCase(event.groupChatId);

      final title = chat?.title ?? '';
      final description = chat?.description ?? '';

      // emit.forEach управляет подпиской автоматически и отменяет ее при необходимости
      await emit.forEach<List<MessageEntity>>(
        _watchGroupMessagesUseCase(event.groupChatId),
        onData: (messages) => GroupChatSuccess(
          messages: messages,
          groupChatTitle: title,
          groupChatDescription: description,
          currentUserId: currentUserId,
        ),
        onError: (error, stackTrace) => GroupChatError(error.toString()),
      );
    } catch (e) {
      emit(GroupChatError(e.toString()));
    }
  }

  Future<void> _onSendGroupMessage(
    SendGroupMessageEvent event,
    Emitter<GroupChatState> emit,
  ) async {
    try {
      final currentUser = await _getCurrentUserUseCase();
      final senderId = currentUser?.email ?? currentUser?.id ?? '';

      await _sendGroupMessageUseCase(
        groupId: event.groupChatId,
        content: event.textMessage,
        senderId: senderId,
      );
    } catch (e) {
      emit(GroupChatError(e.toString()));
    }
  }
}
