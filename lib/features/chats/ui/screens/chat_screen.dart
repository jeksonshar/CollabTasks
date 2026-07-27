import 'package:collab_tasks/core/notifications/chat_notification_service.dart';
import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/chats/ui/blocs/chat_bloc.dart';
import 'package:collab_tasks/features/chats/ui/blocs/chat_event.dart';
import 'package:collab_tasks/features/chats/ui/blocs/chat_state.dart';
import 'package:collab_tasks/features/chats/ui/screens/components/message_bubble.dart';
import 'package:collab_tasks/features/chats/ui/screens/components/message_input_field.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:collab_tasks/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String? opponentName;

  const ChatScreen({super.key, required this.chatId, this.opponentName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with RouteAware {
  late final ChatNotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = getIt<ChatNotificationService>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Подписываемся на отслеживание перехода по экранам
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    // Отписываемся от роутера и сбрасываем activeChatId
    routeObserver.unsubscribe(this);
    if (_notificationService.activeChatId == widget.chatId) {
      _notificationService.activeChatId = null;
    }
    super.dispose();
  }

  /// --- Реализация подписки RouteAware ---

  @override
  void didPush() {
    // Экран открылся впервые -> фиксируем активный chatId
    _notificationService.activeChatId = widget.chatId;
  }

  @override
  void didPopNext() {
    // Вернулись на этот экран с верхнего (например, закрыли модалку/профиль)
    _notificationService.activeChatId = widget.chatId;
  }

  @override
  void didPushNext() {
    // Поверх этого экрана открыли другой -> временно сбрасываем
    _notificationService.activeChatId = null;
  }

  @override
  void didPop() {
    // Экран закрываем совсем -> сбрасываем активный chatId
    _notificationService.activeChatId = null;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return BlocProvider<ChatBloc>(
      create: (_) => getIt<ChatBloc>()..add(LoadMessages(widget.chatId)),
      child: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          String appBarTitle = localizations.direct_chat_toolbarTitle;
          if (state is ChatLoaded) {
            appBarTitle = widget.opponentName ?? state.chatTitle;
          }

          return Scaffold(
            appBar: AppBar(title: Text(appBarTitle)),
            body: Column(
              children: [
                Expanded(child: _buildBody(context, state, widget.chatId)),
                SafeArea(
                  top: false,
                  child: MessageInputField(
                    onSendMessage: (text) {
                      context.read<ChatBloc>().add(SendMessageEvent(widget.chatId, text));
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget _buildBody(BuildContext context, ChatState state, String chatId) {
  if (state is ChatLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (state is ChatError) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          state.message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  if (state is ChatLoaded) {
    final messages = state.messages;
    final currentUserId = FirebaseAuth.instance.currentUser?.email;
    final localization = AppLocalizations.of(context)!;

    if (messages.isEmpty) {
      return Center(child: Text(localization.direct_chat_emptyMessagesTitle));
    }

    return ListView.builder(
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentUserId;
        return MessageBubble(
          message: message,
          isMe: isMe,
          isGroupChat: false,
          onDelete: isMe
              ? () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(localization.direct_chat_deleteMessageConfirmationTitle),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(localization.direct_chat_deleteMessageCancelBtn),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<ChatBloc>().add(DeleteMessageEvent(chatId, message.id));
                            Navigator.pop(dialogContext);
                          },
                          child: Text(localization.direct_chat_deleteMessageConfirmBtn),
                        ),
                      ],
                    ),
                  );
                }
              : null,
        );
      },
    );
  }

  return const SizedBox.shrink();
}
