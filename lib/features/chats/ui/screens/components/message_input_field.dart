import 'dart:async';

import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class MessageInputField extends StatefulWidget {
  final void Function(String) onSendMessage;
  final void Function(bool)? onTypingChanged;

  const MessageInputField({super.key, required this.onSendMessage, this.onTypingChanged});

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  late final TextEditingController _controller;
  bool _isTextNotEmpty = false;
  Timer? _typingDebounceTimer;
  bool _isTypingSent = false;

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

    if (widget.onTypingChanged != null) {
      if (textNotEmpty) {
        if (!_isTypingSent) {
          _isTypingSent = true;
          widget.onTypingChanged!(true);
        }
        _typingDebounceTimer?.cancel();
        _typingDebounceTimer = Timer(const Duration(seconds: 2), () {
          if (_isTypingSent) {
            _isTypingSent = false;
            widget.onTypingChanged!(false);
          }
        });
      } else {
        if (_isTypingSent) {
          _isTypingSent = false;
          widget.onTypingChanged!(false);
        }
        _typingDebounceTimer?.cancel();
      }
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      if (_isTypingSent) {
        _isTypingSent = false;
        widget.onTypingChanged?.call(false);
      }
      _typingDebounceTimer?.cancel();
      widget.onSendMessage(text);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _typingDebounceTimer?.cancel();
    if (_isTypingSent) {
      widget.onTypingChanged?.call(false);
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localization = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: localization.direct_chat_hintTextInputMessage,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
