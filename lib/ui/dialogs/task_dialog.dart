import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:task_manager/l10n/l10n_mixin.dart';

import '../../core/attachment_file_service.dart';
import '../../domain/models/task_attachment.dart';
import 'task_attachment_tile.dart';

const extraPadding = 80;

class TaskDialogResult {
  final String text;
  final String deltaJson;
  final List<TaskAttachment> attachments;

  const TaskDialogResult({required this.text, required this.deltaJson, required this.attachments});
}

class TaskDialog extends StatefulWidget {
  final String? initialDeltaJson;
  final List<TaskAttachment> initialAttachments;

  const TaskDialog({super.key, this.initialDeltaJson, this.initialAttachments = const []});

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

  final List<TaskAttachment> _attachments = [];

  TextSelection _lastSelection = const TextSelection.collapsed(offset: -1);

  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _initQuillController();
    _attachments.addAll(widget.initialAttachments);
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
        selection: TextSelection.collapsed(offset: doc.length - 1),
      );
    } catch (_) {
      // Fallback to plain text
      final doc = quill.Document()..insert(0, data);
      return quill.QuillController(
        document: doc,
        selection: TextSelection.collapsed(offset: doc.length - 1),
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
    final plain = _controller.document.toPlainText().trim();

    Navigator.of(context).pop(
      TaskDialogResult(text: json, deltaJson: plain, attachments: List.unmodifiable(_attachments)),
    );
  }

  Future<void> _pickAttachments() async {
    try {
      debugPrint('Picking attachments 0');
      final dir = await attachmentsDirectory();
      final newItems = await pickAttachmentFiles(dir);

      debugPrint('Picking attachments 1');

      if (!mounted || newItems.isEmpty) return;
      debugPrint('Picking attachments 2');
      setState(() {
        _attachments.addAll(newItems);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text('Не удалось добавить файл: $e')));
      debugPrint('Failed to pick attachments: $e');
    }
  }

  Future<void> _viewAttachment(TaskAttachment attachment) async {
    try {
      final content = await tryReadTextAttachment(attachment);

      if (content != null) {
        if (!mounted) return;

        showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(attachment.name),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: SelectableText(content, style: const TextStyle(fontFamily: 'monospace')),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(localization.cancel),
                ),
              ],
            );
          },
        );
        return;
      }

      debugPrint('open in _viewAttachment: bytes = ${attachment.bytes}');
      await openAttachment(attachment);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text('Не удалось открыть файл: $e')));
    }
  }

  Future<void> _downloadAttachment(TaskAttachment attachment) async {
    try {
      final saved = await downloadAttachmentFile(attachment);

      if (!saved || !mounted) return;

      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(const SnackBar(content: Text('Файл сохранён')));
    } catch (e) {
      if (!mounted) return;
      debugPrint('Не удалось скачать файл: $e');
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text('Не удалось сохранить файл: $e')));
    }
  }

  Future<void> _removeAttachment(TaskAttachment attachment) async {
    setState(() {
      _attachments.removeWhere((e) => e.id == attachment.id);
    });
    final isFileRemoved = await removeAttachmentFile(attachment);
    if (!mounted) return;

    if (!isFileRemoved) {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(localization.deleteFileFailed)));
    } else {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(localization.fileDeleted)));
    }
  }

  Widget _buildAttachments() {
    if (_attachments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('Вложения', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._attachments.map(
          (attachment) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TaskAttachmentTile(
              attachment: attachment,
              onView: () => _viewAttachment(attachment),
              // onOpen: () => openAttachment(attachment),
              onDownload: () => _downloadAttachment(attachment),
              onDelete: () => _removeAttachment(attachment),
            ),
          ),
        ),
      ],
    );
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
                  IconButton(onPressed: _pickAttachments, icon: Icon(Icons.attach_file)),
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

              /// 🔹 Attach zone
              _buildAttachments(),
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
