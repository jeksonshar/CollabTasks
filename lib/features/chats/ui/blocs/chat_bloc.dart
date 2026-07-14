import 'dart:async';

import 'package:collab_tasks/features/chats/domain/models/message_entity.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/send_message_use_case.dart';
import 'package:collab_tasks/features/chats/domain/use_cases/watch_messages_use_case.dart';
import 'package:collab_tasks/features/chats/ui/blocs/chat_event.dart';
import 'package:collab_tasks/features/chats/ui/blocs/chat_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final WatchMessagesUseCase _watchMessagesUseCase;
  final SendMessageUseCase _sendMessageUseCase;

  StreamSubscription<List<MessageEntity>>? _messagesSubscription;

  ChatBloc({
    required WatchMessagesUseCase watchMessagesUseCase,
    required SendMessageUseCase sendMessageUseCase,
  }) : _watchMessagesUseCase = watchMessagesUseCase,
       _sendMessageUseCase = sendMessageUseCase,
       super(const ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<OnMessagesUpdated>(_onMessagesUpdated);
    on<SendMessageEvent>(_onSendMessage);
    on<_OnMessagesLoadFailed>(_onMessagesLoadFailed);
  }

  Future<void> _onLoadMessages(LoadMessages event, Emitter<ChatState> emit) async {
    emit(const ChatLoading());
    await _messagesSubscription?.cancel();

    _messagesSubscription = _watchMessagesUseCase(event.chatId).listen(
      (messages) => add(OnMessagesUpdated(messages)),
      onError: (Object error) => add(_OnMessagesLoadFailed(error.toString())),
    );
  }

  void _onMessagesUpdated(OnMessagesUpdated event, Emitter<ChatState> emit) {
    emit(ChatLoaded(event.messages));
  }

  void _onMessagesLoadFailed(_OnMessagesLoadFailed event, Emitter<ChatState> emit) {
    emit(ChatError(event.error));
  }

  Future<void> _onSendMessage(SendMessageEvent event, Emitter<ChatState> emit) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final senderId = currentUser?.uid ?? '';
      final senderName = currentUser?.displayName ?? currentUser?.email ?? 'Unknown User';

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

  @override
  Future<void> close() async {
    await _messagesSubscription?.cancel();
    return super.close();
  }
}

class _OnMessagesLoadFailed extends ChatEvent {
  final String error;

  const _OnMessagesLoadFailed(this.error);

  @override
  List<Object?> get props => [error];
}
