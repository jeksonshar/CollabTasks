import 'package:collab_tasks/core/notifications/chat_notification_service.dart';
import 'package:collab_tasks/core/paging/chats_paging_constants.dart';
import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/chats/ui/blocs/group_chat_bloc.dart';
import 'package:collab_tasks/features/chats/ui/blocs/group_chat_event.dart';
import 'package:collab_tasks/features/chats/ui/blocs/group_chat_state.dart';
import 'package:collab_tasks/features/chats/ui/screens/components/chat_date_separator.dart';
import 'package:collab_tasks/features/chats/ui/screens/components/message_bubble.dart';
import 'package:collab_tasks/features/chats/ui/screens/components/message_input_field.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:collab_tasks/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;

  const GroupChatScreen({required this.groupId, super.key});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> with RouteAware {
  late final ChatNotificationService _notificationService;
  late final ScrollController _scrollController;
  GroupChatBloc? _groupChatBloc;

  @override
  void initState() {
    super.initState();
    _notificationService = getIt<ChatNotificationService>();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - scrollThreshold) {
      _groupChatBloc?.add(const LoadMoreGroupMessagesEvent());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Подписываемся на события навигатора
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    // Отписываемся от роутера и сбрасываем activeGroupId
    routeObserver.unsubscribe(this);
    if (_notificationService.activeGroupId == widget.groupId) {
      _notificationService.activeGroupId = null;
    }
    _scrollController.dispose();
    super.dispose();
  }

  /// --- Управление активным экраном с помощью RouteAware ---

  @override
  void didPush() {
    // Экран открылся — регистрируем activeGroupId
    _notificationService.activeGroupId = widget.groupId;
  }

  @override
  void didPopNext() {
    // Вернулись на этот экран с верхнего — восстанавливаем activeGroupId
    _notificationService.activeGroupId = widget.groupId;
  }

  @override
  void didPushNext() {
    // Поверх этого экрана открыли другой — сбрасываем активный ID
    _notificationService.activeGroupId = null;
  }

  @override
  void didPop() {
    // Экран закрываем — сбрасываем activeGroupId
    _notificationService.activeGroupId = null;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocProvider<GroupChatBloc>(
      create: (_) {
        final bloc = getIt<GroupChatBloc>()..add(LoadGroupMessagesEvent(widget.groupId));
        _groupChatBloc = bloc;
        return bloc;
      },
      child: BlocBuilder<GroupChatBloc, GroupChatState>(
        builder: (context, state) {
          String title = '';
          if (state is GroupChatSuccess) {
            title = state.groupChatTitle;
          }

          return Scaffold(
            appBar: AppBar(
              titleSpacing: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title),
                  const SizedBox(height: 4),
                  Text(
                    localizations.group_chat_toolbarSabTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            body: Column(
              children: [
                Expanded(child: _buildBody(context, state)),
                SafeArea(
                  top: false,
                  child: Builder(
                    builder: (context) {
                      return MessageInputField(
                        onSendMessage: (content) {
                          context.read<GroupChatBloc>().add(
                            SendGroupMessageEvent(widget.groupId, content),
                          );
                        },
                      );
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

  Widget _buildBody(BuildContext context, GroupChatState state) {
    if (state is GroupChatLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is GroupChatError) {
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

    if (state is GroupChatSuccess) {
      final messages = state.messages;
      final localization = AppLocalizations.of(context)!;

      if (messages.isEmpty) {
        return Center(child: Text(localization.direct_chat_emptyMessagesTitle));
      }

      return ListView.builder(
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
            isGroupChat: true,
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
