import 'package:flutter/material.dart';

class MessageInputField extends StatefulWidget {
  final void Function(String) onSendMessage;

  const MessageInputField({super.key, required this.onSendMessage});

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  late final TextEditingController _controller;
  bool _isTextNotEmpty = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    final textNotEmpty = _controller.text.trim().isNotEmpty;
    if (_isTextNotEmpty != textNotEmpty) {
      setState(() {
        _isTextNotEmpty = textNotEmpty;
      });
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isTextNotEmpty ? _submit : null,
            icon: const Icon(Icons.send),
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
