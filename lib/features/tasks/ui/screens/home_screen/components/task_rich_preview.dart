import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class TaskRichPreview extends StatefulWidget {
  const TaskRichPreview({super.key, required this.deltaJson});

  final String deltaJson;

  @override
  State<TaskRichPreview> createState() => _TaskRichPreviewState();
}

class _TaskRichPreviewState extends State<TaskRichPreview> {
  quill.QuillController? _controller;
  FocusNode? _focusNode;
  ScrollController? _scrollController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initResources(widget.deltaJson);
  }

  @override
  void didUpdateWidget(covariant TaskRichPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.deltaJson != widget.deltaJson) {
      _disposeResources();
      _initResources(widget.deltaJson);
    }
  }

  void _initResources(String deltaJson) {
    try {
      final document = quill.Document.fromJson(jsonDecode(deltaJson) as List<dynamic>);

      _controller = quill.QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
      _focusNode = FocusNode(canRequestFocus: false);
      _scrollController = ScrollController();
      _hasError = false;
    } catch (_) {
      _controller = null;
      _focusNode = null;
      _scrollController = null;
      _hasError = true;
    }
  }

  void _disposeResources() {
    _controller?.dispose();
    _focusNode?.dispose();
    _scrollController?.dispose();

    _controller = null;
    _focusNode = null;
    _scrollController = null;
  }

  @override
  void dispose() {
    _disposeResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const fixedTextColor = Colors.black87;

    if (_hasError || _controller == null || _focusNode == null || _scrollController == null) {
      return Text(
        widget.deltaJson,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: fixedTextColor),
      );
    }

    return IgnorePointer(
      child: quill.QuillEditor(
        controller: _controller!,
        focusNode: _focusNode!,
        scrollController: _scrollController!,
        config: const quill.QuillEditorConfig(
          expands: false,
          padding: EdgeInsets.zero,
          // Явно передаем стили для базового текста в обход темы
          customStyles: quill.DefaultStyles(
            paragraph: quill.DefaultTextBlockStyle(
              TextStyle(color: fixedTextColor, fontSize: 16),
              quill.HorizontalSpacing(0, 0),
              quill.VerticalSpacing(0, 0),
              quill.VerticalSpacing(0, 0),
              null,
            ),
          ),
        ),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   if (_hasError || _controller == null || _focusNode == null || _scrollController == null) {
  //     return Text(widget.deltaJson, maxLines: 2, overflow: TextOverflow.ellipsis);
  //   }
  //
  //   return IgnorePointer(
  //     // ignoring: true, // 👈 disables interaction completely
  //     child: quill.QuillEditor(
  //       controller: _controller!,
  //       focusNode: _focusNode!,
  //       scrollController: _scrollController!,
  //       config: const quill.QuillEditorConfig(
  //         expands: false,
  //         padding: EdgeInsets.zero,
  //         // enableInteractiveSelection: false, // 👈 remove the selection
  //       ),
  //     ),
  //   );
  // }
}
