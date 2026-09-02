import 'package:collab_tasks/core/notifications/chat_notification_service.dart';
import 'package:collab_tasks/core/paging/chats_paging_constants.dart';
import 'package:collab_tasks/core/utils/auth_utils.dart';
import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/chats/ui/blocs/chat_bloc.dart';
import 'package:collab_tasks/features/chats/ui/blocs/chat_event.dart';
import 'package:collab_tasks/features/chats/ui/blocs/chat_state.dart';
import 'package:collab_tasks/features/chats/ui/screens/components/chat_date_separator.dart';
import 'package:collab_tasks/features/chats/ui/screens/components/message_bubble.dart';
import 'package:collab_tasks/features/chats/ui/screens/components/message_input_field.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:collab_tasks/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String? opponentName;

  const ChatScreen({super.key, required this.chatId, this.opponentName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with RouteAware, WidgetsBindingObserver {
  late final ChatNotificationService _notificationService;
  late final ScrollController _scrollController;
  ChatBloc? _chatBloc;

  @override
  void initState() {
    super.initState();
    _notificationService = getIt<ChatNotificationService>();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - scrollThreshold) {
      _chatBloc?.add(const LoadMoreMessages());
    }
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _chatBloc?.add(SendTypingEvent(widget.chatId, false));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Отписываемся от роутера и сбрасываем activeChatId
    routeObserver.unsubscribe(this);
    if (_notificationService.activeChatId == widget.chatId) {
      _notificationService.activeChatId = null;
    }
    _scrollController.dispose();
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
    final localization = AppLocalizations.of(context)!;
    return BlocProvider<ChatBloc>(
      create: (_) {
        final bloc = getIt<ChatBloc>()..add(LoadMessages(widget.chatId));
        _chatBloc = bloc;
        return bloc;
      },
      child: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          // Локализация заглавия экрана на уровне UI
          String appBarTitle = localization.direct_chat_toolbarTitle;
          if (state is ChatLoaded) {
            appBarTitle =
                widget.opponentName ??
                (state.opponentEmail.isNotEmpty
                    ? state.opponentEmail
                    : localization.direct_chat_toolbarTitle);
          }

          return Scaffold(
            appBar: AppBar(
              titleSpacing: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    appBarTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (state is ChatLoaded && chatBackend == ChatBackend.webSocket) ...[
                    const SizedBox(height: 4),
                    _buildSubtitle(context, state),
                  ],
                ],
              ),
            ),
            body: Column(
              children: [
                Expanded(child: _buildBody(context, state, widget.chatId)),
                SafeArea(
                  top: false,
                  child: MessageInputField(
                    onSendMessage: (text) {
                      context.read<ChatBloc>().add(SendMessageEvent(widget.chatId, text));
                    },
                    onTypingChanged: (isTyping) {
                      context.read<ChatBloc>().add(SendTypingEvent(widget.chatId, isTyping));
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

  Widget _buildSubtitle(BuildContext context, ChatLoaded state) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final subtitleColor = isLight ? Colors.black54 : Colors.white70;
    final localization = AppLocalizations.of(context)!;

    if (state.isOpponentTyping) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSubtitleIndicator(Colors.green),
          const SizedBox(width: 12),
          Text(
            localization.direct_chat_typingStatus,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      );
    }

    final status = state.opponentStatus;
    if (status == null) {
      return const SizedBox.shrink();
    }

    final isOnline = status.isOnline;
    final dotColor = isOnline ? Colors.green : Colors.grey;

    String statusText;
    if (isOnline) {
      statusText = localization.direct_chat_opponentStatusOnline;
    } else {
      final lastSeenMillis = status.lastSeenMillis;
      if (lastSeenMillis != null && lastSeenMillis > 0) {
        final dt = DateTime.fromMillisecondsSinceEpoch(lastSeenMillis).toLocal();
        final formatted = DateFormat('dd.MM.yyyy HH:mm').format(dt);
        statusText = localization.direct_chat_wasOnline(formatted);
      } else {
        statusText = localization.direct_chat_opponentStatusOffline;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSubtitleIndicator(dotColor),
        const SizedBox(width: 12),
        Text(
          statusText,
          style: TextStyle(fontSize: 12, color: isOnline ? Colors.green : subtitleColor),
        ),
      ],
    );
  }

  Widget _buildSubtitleIndicator(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
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
      final localization = AppLocalizations.of(context)!;

      if (messages.isEmpty) {
        return Center(child: Text(localization.direct_chat_emptyMessagesTitle));
      }

      return ListView.builder(
        key: ValueKey('chat_list_$chatId'),
        controller: _scrollController,
        reverse: true,
        itemCount: messages.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messages.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final message = messages[index];
          final isMe = message.senderId == state.currentUserId;
          final messageDate = DateTime.fromMillisecondsSinceEpoch(
            message.createdAtMillis,
          ).toLocal();

          final isFirstMessageOfDay =
              index == messages.length - 1 ||
              !_isSameDay(
                messageDate,
                DateTime.fromMillisecondsSinceEpoch(messages[index + 1].createdAtMillis).toLocal(),
              );

          final bubble = MessageBubble(
            key: ValueKey(message.id),
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

          if (isFirstMessageOfDay) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ChatDateSeparator(date: messageDate),
                bubble,
              ],
            );
          }

          return bubble;
        },
      );
    }

    return const SizedBox.shrink();
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
