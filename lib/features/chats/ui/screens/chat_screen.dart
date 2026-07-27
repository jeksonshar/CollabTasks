import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/chats/ui/blocs/chat_bloc.dart';
import 'package:collab_tasks/features/chats/ui/blocs/chat_event.dart';
import 'package:collab_tasks/features/chats/ui/blocs/chat_state.dart';
import 'package:collab_tasks/features/chats/ui/screens/components/message_bubble.dart';
import 'package:collab_tasks/features/chats/ui/screens/components/message_input_field.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// class ChatScreen extends StatelessWidget {
//   final String chatId;
//
//   const ChatScreen({super.key, required this.chatId});
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider<ChatBloc>(
//       create: (_) => getIt<ChatBloc>()..add(LoadMessages(chatId)),
//       child: Scaffold(
//         appBar: AppBar(title: const Text('Chat')),
//         body: Column(
//           children: [
//             Expanded(
//               child: BlocBuilder<ChatBloc, ChatState>(
//                 builder: (context, state) {
//                   return _buildBody(context, state);
//                 },
//               ),
//             ),
//             SafeArea(
//               top: false,
//               child: Builder(
//                 builder: (context) {
//                   return MessageInputField(
//                     onSendMessage: (text) {
//                       context.read<ChatBloc>().add(SendMessageEvent(chatId, text));
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class ChatScreen extends StatelessWidget {
  final String chatId;
  final String? opponentName;

  const ChatScreen({super.key, required this.chatId, this.opponentName});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return BlocProvider<ChatBloc>(
      create: (_) => getIt<ChatBloc>()..add(LoadMessages(chatId)),
      child: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          // 1. Вычисляем заголовок на основе текущего стейта и opponentName
          String appBarTitle = localizations.direct_chat_toolbarTitle;
          if (state is ChatLoaded) {
            appBarTitle = opponentName ?? state.chatTitle;
          }

          return Scaffold(
            appBar: AppBar(title: Text(appBarTitle)),
            body: Column(
              children: [
                Expanded(child: _buildBody(context, state, chatId)),
                SafeArea(
                  top: false,
                  child: MessageInputField(
                    onSendMessage: (text) {
                      context.read<ChatBloc>().add(SendMessageEvent(chatId, text));
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
