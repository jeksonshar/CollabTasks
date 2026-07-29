import 'dart:async';

import 'package:collab_tasks/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:collab_tasks/features/chats/domain/models/message_entity.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/delete_message_use_case.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/get_chat_use_case.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/send_message_use_case.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/watch_messages_use_case.dart';
import 'package:collab_tasks/features/chats/ui/blocs/chat_event.dart';
import 'package:collab_tasks/features/chats/ui/blocs/chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final WatchMessagesUseCase _watchMessagesUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final GetChatUseCase _getChatUseCase;
  final DeleteMessageUseCase _deleteMessageUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  ChatBloc({
    required WatchMessagesUseCase watchMessagesUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required GetChatUseCase getChatUseCase,
    required DeleteMessageUseCase deleteMessageUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  }) : _watchMessagesUseCase = watchMessagesUseCase,
       _sendMessageUseCase = sendMessageUseCase,
       _getChatUseCase = getChatUseCase,
       _deleteMessageUseCase = deleteMessageUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       super(const ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<DeleteMessageEvent>(_onDeleteMessage);
  }

  Future<void> _onLoadMessages(LoadMessages event, Emitter<ChatState> emit) async {
    emit(const ChatLoading());

    try {
      final currentUser = await _getCurrentUserUseCase();
      final currentUserEmail = currentUser?.email ?? '';

      final chat = await _getChatUseCase(event.chatId);
      final participantIds = chat?.participantIds ?? [];

      // 2. Ищем email собеседника
      final opponentEmail = participantIds.firstWhere(
        (id) => id != currentUserEmail,
        orElse: () => '',
      );

      // Использование emit.forEach автоматически отменяет предыдущий Stream при вызове нового handler
      await emit.forEach<List<MessageEntity>>(
        _watchMessagesUseCase(event.chatId),
        onData: (messages) => ChatLoaded(
          messages: messages,
          opponentEmail: opponentEmail,
          currentUserId: currentUserEmail,
        ),
        onError: (error, stackTrace) => ChatError(error.toString()),
      );
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onSendMessage(SendMessageEvent event, Emitter<ChatState> emit) async {
    try {
      final currentUser = await _getCurrentUserUseCase();
      final senderId = currentUser?.email ?? '';
      final senderName = currentUser?.displayName ?? currentUser?.email ?? '';

      final message = MessageEntity(
        id: const Uuid().v4(),
        senderId: senderId,
        senderName: senderName,
        text: event.text,
        createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      );

      await _sendMessageUseCase(event.chatId, message);
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onDeleteMessage(DeleteMessageEvent event, Emitter<ChatState> emit) async {
    try {
      await _deleteMessageUseCase(event.chatId, event.messageId);
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }
}
