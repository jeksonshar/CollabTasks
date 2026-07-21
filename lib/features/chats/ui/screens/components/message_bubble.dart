import 'package:collab_tasks/features/chats/domain/models/message_entity.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final VoidCallback? onDelete;

  const MessageBubble({super.key, required this.message, required this.isMe, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final bubbleColor = isMe
        ? theme.colorScheme.primary
        : (isLight ? Colors.grey[200] : Colors.grey[800]);

    final textColor = isMe
        ? theme.colorScheme.onPrimary
        : (isLight ? Colors.black87 : Colors.white70);

    final timeColor = isMe
        ? (isLight ? Colors.white70 : Colors.black45)
        : (isLight ? Colors.black54 : Colors.white54);

    final dateTime = DateTime.fromMillisecondsSinceEpoch(message.createdAtMillis);
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final formattedTime = '$hour:$minute';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMe ? onDelete : null,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(isMe ? 12 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message.text, style: TextStyle(color: textColor, fontSize: 15)),
              const SizedBox(height: 4),
              Text(formattedTime, style: TextStyle(fontSize: 10, color: timeColor)),
            ],
          ),
        ),
      ),
    );
  }
}
