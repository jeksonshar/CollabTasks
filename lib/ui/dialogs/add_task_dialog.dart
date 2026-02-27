import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  late final quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _dialogScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = quill.QuillController.basic();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _dialogScrollController.dispose();
    super.dispose();
  }

  bool get _isEmpty {
    final doc = _controller.document.toDelta();
    return doc.isEmpty || _controller.document.toPlainText().trim().isEmpty;
  }

  void _submit() {
    if (_isEmpty) return;

    final delta = _controller.document.toDelta();
    final json = jsonEncode(delta.toJson());

    Navigator.of(context).pop(json);
  }
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    // Скроллим к редактору, если клавиатура открыта
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dialogScrollController.hasClients && media.viewInsets.bottom > 0) {
        _dialogScrollController.animateTo(
          _dialogScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 50),
          curve: Curves.easeOut,
        );
      }
    });

    return AlertDialog(
      title: const Text('Add Task'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 700,
          maxHeight: media.size.height * 0.8,
        ),
        child: SingleChildScrollView(
          controller: _dialogScrollController, // 👈 управляем скроллом
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// 🔹 Toolbar
              quill.QuillSimpleToolbar(
                controller: _controller,
                config: const quill.QuillSimpleToolbarConfig(
                  showDividers: true,
                  showBoldButton: true,
                  showItalicButton: true,
                  showStrikeThrough: true,
                  showHeaderStyle: true,
                  showColorButton: true,
                  showBackgroundColorButton: true,
                  showFontSize: true,
                  showListNumbers: true,
                  showListBullets: true,
                  showListCheck: false,
                  showDirection: false,
                  showSearchButton: false,

                ),
              ),

              const SizedBox(height: 8),

              /// 🔹 Editor
              Container(
                height: 300,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: quill.QuillEditor(
                  controller: _controller,
                  focusNode: _focusNode,
                  scrollController: _scrollController,
                  config: const quill.QuillEditorConfig(
                    placeholder: 'Enter task text...',
                    expands: false,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final enabled = _controller.document.toPlainText().trim().isNotEmpty;
            return ElevatedButton(
              onPressed: enabled ? _submit : null,
              child: const Text('Enter'),
            );
          },
        ),
      ],
    );
  }
}