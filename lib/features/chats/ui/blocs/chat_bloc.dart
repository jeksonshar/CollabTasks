import 'dart:async';

import 'package:collab_tasks/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:collab_tasks/features/chats/domain/models/message_entity.dart';
import 'package:collab_tasks/features/chats/domain/models/typing_status_entity.dart';
import 'package:collab_tasks/features/chats/domain/models/user_status_entity.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/delete_message_use_case.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/get_chat_use_case.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/send_message_use_case.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/send_typing_status_use_case.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/watch_messages_use_case.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/watch_typing_status_use_case.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/watch_user_status_use_case.dart';
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
  final WatchUserStatusUseCase _watchUserStatusUseCase;
  final WatchTypingStatusUseCase _watchTypingStatusUseCase;
  final SendTypingStatusUseCase _sendTypingStatusUseCase;

  StreamSubscription<List<MessageEntity>>? _messagesSubscription;
  StreamSubscription<UserStatusEntity>? _userStatusSubscription;
  StreamSubscription<TypingStatusEntity>? _typingSubscription;

  String _opponentEmail = '';
  String _currentUserEmail = '';

  ChatBloc({
    required WatchMessagesUseCase watchMessagesUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required GetChatUseCase getChatUseCase,
    required DeleteMessageUseCase deleteMessageUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required WatchUserStatusUseCase watchUserStatusUseCase,
    required WatchTypingStatusUseCase watchTypingStatusUseCase,
    required SendTypingStatusUseCase sendTypingStatusUseCase,
  }) : _watchMessagesUseCase = watchMessagesUseCase,
       _sendMessageUseCase = sendMessageUseCase,
       _getChatUseCase = getChatUseCase,
       _deleteMessageUseCase = deleteMessageUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _watchUserStatusUseCase = watchUserStatusUseCase,
       _watchTypingStatusUseCase = watchTypingStatusUseCase,
       _sendTypingStatusUseCase = sendTypingStatusUseCase,
       super(const ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<DeleteMessageEvent>(_onDeleteMessage);
    on<SendTypingEvent>(_onSendTyping);
    on<MessagesUpdated>(_onMessagesUpdated);
    on<UserStatusUpdated>(_onUserStatusUpdated);
    on<TypingStatusUpdated>(_onTypingStatusUpdated);
  }

  Future<void> _onLoadMessages(LoadMessages event, Emitter<ChatState> emit) async {
    emit(const ChatLoading());

    await _cancelSubscriptions();

    try {
      final currentUser = await _getCurrentUserUseCase();
      _currentUserEmail = currentUser?.email ?? '';

      final chat = await _getChatUseCase(event.chatId);
      final participantIds = chat?.participantIds ?? [];

      // Ищем идентификатор (email/id) собеседника
      _opponentEmail = participantIds.firstWhere(
        (id) => id.trim().toLowerCase() != _currentUserEmail.trim().toLowerCase(),
        orElse: () => '',
      );

      _messagesSubscription = _watchMessagesUseCase(event.chatId).listen(
        (messages) => add(MessagesUpdated(messages)),
        onError: (error) => add(const MessagesUpdated([])),
      );

      if (_opponentEmail.isNotEmpty) {
        _userStatusSubscription = _watchUserStatusUseCase(
          _opponentEmail,
        ).listen((userStatus) => add(UserStatusUpdated(userStatus)));
      }

      _typingSubscription = _watchTypingStatusUseCase(
        event.chatId,
      ).listen((typingStatus) => add(TypingStatusUpdated(typingStatus)));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  void _onMessagesUpdated(MessagesUpdated event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(messages: event.messages));
    } else {
      emit(
        ChatLoaded(
          messages: event.messages,
          opponentEmail: _opponentEmail,
          currentUserId: _currentUserEmail,
        ),
      );
    }
  }

  void _onUserStatusUpdated(UserStatusUpdated event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(opponentStatus: event.userStatus));
    }
  }

  void _onTypingStatusUpdated(TypingStatusUpdated event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final isOpponent =
          event.typingStatus.userId.trim().toLowerCase() != _currentUserEmail.trim().toLowerCase();
      final isTyping = isOpponent && event.typingStatus.isTyping;
      emit((state as ChatLoaded).copyWith(isOpponentTyping: isTyping));
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

  Future<void> _onSendTyping(SendTypingEvent event, Emitter<ChatState> emit) async {
    try {
      await _sendTypingStatusUseCase(event.chatId, event.isTyping);
    } catch (e) {
      // Fire-and-forget
    }
  }

  Future<void> _cancelSubscriptions() async {
    await _messagesSubscription?.cancel();
    _messagesSubscription = null;
    await _userStatusSubscription?.cancel();
    _userStatusSubscription = null;
    await _typingSubscription?.cancel();
    _typingSubscription = null;
  }

  @override
  Future<void> close() async {
    await _cancelSubscriptions();
    return super.close();
  }
}
