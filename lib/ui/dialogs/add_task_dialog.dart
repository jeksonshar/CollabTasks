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
  final GlobalKey _editorKey = GlobalKey(); // key for the editor container

  @override
  void initState() {
    super.initState();
    _controller = quill.QuillController.basic();

    // subscribe to changes in the controller (text/cursor)
    _controller.addListener(() {
      // Scroll only if the editor is in focus
      if (_focusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _ensureEditorVisible());
      }
    });

    // It's also worth checking when you focus (for example, switch to the editor)
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _ensureEditorVisible());
      }
    });
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

  // Logic Center: Calculates whether the bottom border of the editor is visible, taking
  // the keyboard into account.
  // _dialogScrollController.hasClients check before reading position/offset
  Future<void> _ensureEditorVisible({bool isNeedDelay = false}) async {
    if (!_dialogScrollController.hasClients) return;
    if (_editorKey.currentContext == null) return;

    if (isNeedDelay) {
      // delay need to draw all the fields for calculating the sizes to scroll (50-250 ms)
      const Duration attemptDelay = Duration(milliseconds: 100);
      await Future<void>.delayed(attemptDelay);
    }

    if (!mounted) return;

    final media = MediaQuery.of(context);
    final keyboardInset = media.viewInsets.bottom;
    final screenHeight = media.size.height;

    final renderBox = _editorKey.currentContext!.findRenderObject() as RenderBox;
    final editorTopLeftGlobal = renderBox.localToGlobal(Offset.zero);
    final editorBottomGlobal = editorTopLeftGlobal.dy + renderBox.size.height;

    // Visible screen height without keyboard and padding at the bottom
    final visibleHeight = screenHeight - keyboardInset - editorBottomGlobal;

    // If the bottom point of the editor is below the visible area, scroll down.
    if (editorBottomGlobal > visibleHeight) {
      final diff = editorBottomGlobal - visibleHeight;
      final target = (_dialogScrollController.offset + diff).clamp(
        0.0,
        _dialogScrollController.position.maxScrollExtent,
      );
      _dialogScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 50),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    /* TODO
         сейчас если в эдиторе с длинным текстом тапать в начале или в середине то после
         открытия клавиатуры происходит скрол к самому низу, а не к месту тапа,
         это надо исправить
    */

    // When opening the keyboard, scroll down the dialog to fully display the editor, used delay.
    _ensureEditorVisible(isNeedDelay: true);

    return AlertDialog(
      title: const Text('Add Task'),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 700, maxHeight: media.size.height * 0.8),
        child: SingleChildScrollView(
          controller: _dialogScrollController, // 👈 control scrolling
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

              /// 🔹 Editor (wrapped in a key)
              Container(
                key: _editorKey,
                constraints: const BoxConstraints(minHeight: 100),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
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
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final enabled = _controller.document.toPlainText().trim().isNotEmpty;
            return ElevatedButton(onPressed: enabled ? _submit : null, child: const Text('Enter'));
          },
        ),
      ],
    );
  }
}
