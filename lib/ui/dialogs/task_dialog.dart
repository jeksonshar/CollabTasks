import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:task_manager/l10n/l10n_mixin.dart';

const extraPadding = 80;

class TaskDialog extends StatefulWidget {
  final String? initialDeltaJson;

  const TaskDialog({super.key, this.initialDeltaJson});

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> with L10nMixin {
  late final quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _dialogScrollController = ScrollController();
  final ScrollController _toolbarScrollController = ScrollController();
  final GlobalKey _editorKey = GlobalKey(); // key for the editor container

  TextSelection _lastSelection = const TextSelection.collapsed(offset: -1);

  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _initQuillController();
    _setupListeners();
  }

  void _initQuillController() {
    if (widget.initialDeltaJson != null) {
      _controller = _createControllerFromData(widget.initialDeltaJson!);
    } else {
      _controller = quill.QuillController.basic();
    }
    _lastSelection = _controller.selection;
  }

  quill.QuillController _createControllerFromData(String data) {
    try {
      // Trying to parse it as Delta JSON.
      final doc = quill.Document.fromJson(jsonDecode(data) as List<dynamic>);
      return quill.QuillController(
        document: doc,
        selection: TextSelection.collapsed(offset: doc.toPlainText().length),
      );
    } catch (_) {
      // Fallback to plain text
      final doc = quill.Document()..insert(0, data);
      return quill.QuillController(
        document: doc,
        selection: TextSelection.collapsed(offset: doc.toPlainText().length),
      );
    }
  }

  void _setupListeners() {
    _controller.addListener(_onSelectionChanged);
    _focusNode.addListener(_onFocusChanged);
    _toolbarScrollController.addListener(_updateToolbarScrollIndicators);

    // One-time call after rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateToolbarScrollIndicators();
    });
  }

  void _onSelectionChanged() {
    final sel = _controller.selection;
    if (sel != _lastSelection) {
      _lastSelection = sel;
      // If there is no focus, there is no need to scroll.
      if (_focusNode.hasFocus) {
        _scheduleEnsureVisible();
      }
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _scheduleEnsureVisible(isNeedDelay: true);
    }
  }

  void _scheduleEnsureVisible({bool isNeedDelay = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureEditorVisible(isNeedDelay: isNeedDelay);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onSelectionChanged);
    _focusNode.removeListener(_onFocusChanged);
    _toolbarScrollController.removeListener(_updateToolbarScrollIndicators);

    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _dialogScrollController.dispose();
    _toolbarScrollController.dispose();
    super.dispose();
  }

  bool get _isEmpty {
    final doc = _controller.document.toDelta();
    return doc.isEmpty || _controller.document.toPlainText().trim().isEmpty;
  }

  void _updateToolbarScrollIndicators() {
    if (!_toolbarScrollController.hasClients) return;

    final position = _toolbarScrollController.position;
    final canLeft = position.pixels > 0;
    final canRight = position.pixels < position.maxScrollExtent;

    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
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
    final bottomSafeArea = media.viewPadding.bottom;
    final visibleBottom = screenHeight - keyboardInset - bottomSafeArea;

    try {
      final renderBox = _editorKey.currentContext!.findRenderObject() as RenderBox;
      final editorTopLeftGlobal = renderBox.localToGlobal(Offset.zero);
      final editorBottomGlobal = editorTopLeftGlobal.dy + renderBox.size.height + extraPadding;
      final visibleTop = media.viewPadding.top; // верхняя видимая граница

      debugPrint(
        'ensureEditorVisible: editorBottomGlobal = $editorBottomGlobal, visibleBottom = $visibleBottom',
      );

      if (_isCaretVisible(visibleTop, visibleBottom)) {
        debugPrint('ensureEditorVisible: caret already visible — skip scroll');
        return;
      } else {
        double diff;
        if (editorBottomGlobal > visibleBottom) {
          diff = editorBottomGlobal - visibleBottom;
          debugPrint('ensureEditorVisible: > diff = $diff');
        } else {
          final visibleHeight = screenHeight - keyboardInset - editorBottomGlobal;
          diff = editorBottomGlobal - visibleHeight;
          debugPrint('ensureEditorVisible: < diff = $diff');
        }
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
    } catch (e) {
      debugPrint('ensureEditorVisible: final fallback failed: $e');
    }
  }

  bool _isCaretVisible(double visibleTop, double visibleBottom, {double padding = 8.0}) {
    final ctx = _editorKey.currentContext;
    if (ctx == null) return false;

    final sel = _controller.selection;
    if (!sel.isValid) return false;

    // normalize visible bounds with padding
    final top = visibleTop + padding;
    final bottom = visibleBottom - padding;

    // приближённая оценка позиции по offset / длина_текста
    try {
      final ro = ctx.findRenderObject();
      if (ro is RenderBox) {
        final editorTopGlobal = ro.localToGlobal(Offset.zero).dy + extraPadding;
        final editorHeight = ro.size.height;

        final text = _controller.document.toPlainText();
        final docLen = text.isEmpty ? 1 : text.length;
        final selOffset = sel.baseOffset.clamp(0, docLen);
        final ratio = selOffset / docLen;
        final approxCaretYGlobal = editorTopGlobal + ratio * editorHeight;

        debugPrint(
          'ensureEditorVisible: approxCaretYGlobal = $approxCaretYGlobal, top = $top, bottom = $bottom',
        );

        return approxCaretYGlobal >= top && approxCaretYGlobal <= bottom;
      }
    } catch (e) {
      debugPrint('ensureEditorVisible: isCaretVisible: proportional check failed: $e');
    }

    debugPrint('ensureEditorVisible: ничего не помогло — считаем невидимым');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    // When opening the keyboard, scroll down the dialog to fully display the editor, used delay.
    _ensureEditorVisible(isNeedDelay: true);

    final title = widget.initialDeltaJson != null
        ? Text(localization.editTaskTitle)
        : Text(localization.addTaskTitle);

    final actionBtnText = widget.initialDeltaJson != null
        ? Text(localization.update)
        : Text(localization.enter);

    return AlertDialog(
      title: title,
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 700, maxHeight: media.size.height * 0.8),
        child: SingleChildScrollView(
          controller: _dialogScrollController, // 👈 control scrolling
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Expanded() is necessary that the Text takes up only the available space
                  // and does not push the IconButton beyond the Row.
                  // It is necessary that the Text takes up only the available space and does not
                  // push the IconButton beyond the Row.
                  Expanded(
                    child: Text(
                      localization.attachFileTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: "Roboto",
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO Implement file attachment logic here
                    },
                    icon: Icon(Icons.attach_file),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  localization.formattingTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: "Roboto",
                  ),
                ),
              ),
              const SizedBox(height: 2),

              /// 🔹 Toolbar
              SizedBox(
                height: 48,
                child: Stack(
                  children: [
                    // сам тулбар с возможностью скролла
                    ScrollConfiguration(
                      behavior: const MaterialScrollBehavior().copyWith(
                        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
                      ),
                      child: SingleChildScrollView(
                        controller: _toolbarScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                          ],
                        ),
                      ),
                    ),

                    // Левый градиент
                    if (_canScrollLeft)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: Container(
                            width: 24,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.surface,
                                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Правый градиент
                    if (_canScrollRight)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: Container(
                            width: 24,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
                                  Theme.of(context).colorScheme.surface,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
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
                  config: quill.QuillEditorConfig(
                    placeholder: localization.editorPlaceholder,
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
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(localization.cancel)),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final enabled = _controller.document.toPlainText().trim().isNotEmpty;
            return ElevatedButton(onPressed: enabled ? _submit : null, child: actionBtnText);
          },
        ),
      ],
    );
  }
}
