import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:task_manager/l10n/l10n_mixin.dart';
import 'package:task_manager/ui/dialogs/task_dialog/ui_components/task_attachments_section.dart';
import 'package:task_manager/ui/dialogs/task_dialog/ui_components/task_formatter_editor_section.dart';

import '../../../domain/models/task_attachment.dart';

const extraPadding = 90.0; // TODO 6.04 it is no good, in the future, need to calculating this size

class TaskDialogResult {
  final String textJson;
  final List<TaskAttachment> attachments;

  const TaskDialogResult({required this.textJson, required this.attachments});
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
  final ScrollController _editorScrollController = ScrollController();
  final ScrollController _dialogScrollController = ScrollController();

  final GlobalKey _editorKey = GlobalKey();

  final List<TaskAttachment> _attachments = [];

  TextSelection _lastSelection = const TextSelection.collapsed(offset: -1);

  @override
  void initState() {
    super.initState();

    _initController();

    _attachments.addAll(widget.initialAttachments);

    _setupListeners();
  }

  void _initController() {
    if (widget.initialDeltaJson != null) {
      try {
        final doc = quill.Document.fromJson(jsonDecode(widget.initialDeltaJson!) as List);

        _controller = quill.QuillController(
          document: doc,
          selection: TextSelection.collapsed(offset: doc.length > 0 ? doc.length - 1 : 0),
        );
      } catch (_) {
        final doc = quill.Document()..insert(0, widget.initialDeltaJson!);

        _controller = quill.QuillController(
          document: doc,
          selection: TextSelection.collapsed(offset: doc.length),
        );
      }
    } else {
      _controller = quill.QuillController.basic();
    }

    _lastSelection = _controller.selection;
  }

  void _setupListeners() {
    _controller.addListener(_onSelectionChanged);
  }

  void _onSelectionChanged() {
    final sel = _controller.selection;
    if (sel == _lastSelection) return;

    _lastSelection = sel;
  }

  bool get _isEmpty => _controller.document.toPlainText().trim().isEmpty;

  void _submit() {
    if (_isEmpty) return;

    final delta = _controller.document.toDelta();

    Navigator.of(context).pop(
      TaskDialogResult(
        textJson: jsonEncode(delta.toJson()),
        attachments: List.unmodifiable(_attachments),
      ),
    );
  }

  void _onAttachmentsChanged(List<TaskAttachment> list) {
    _attachments
      ..clear()
      ..addAll(list);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _editorScrollController.dispose();
    _dialogScrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    final isEdit = widget.initialDeltaJson != null;

    return AlertDialog(
      title: Text(isEdit ? localization.editTaskTitle : localization.addTaskTitle),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 700, maxHeight: media.size.height * 0.8),
        child: SingleChildScrollView(
          controller: _dialogScrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TaskFormatterEditorSection(
                editorKey: _editorKey,
                controller: _controller,
                focusNode: _focusNode,
                scrollController: _editorScrollController,
                formattingTitle: localization.formattingTitle,
                editorPlaceholder: localization.editorPlaceholder,
              ),
              const SizedBox(height: 12),
              TaskAttachmentsSection(
                initialAttachments: widget.initialAttachments,
                onChanged: _onAttachmentsChanged,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(localization.cancel)),
        AnimatedBuilder(
          animation: _controller,
          builder: (_, _) {
            final enabled = !_isEmpty;

            return ElevatedButton(
              onPressed: enabled ? _submit : null,
              child: Text(isEdit ? localization.update : localization.enter),
            );
          },
        ),
      ],
    );
  }
}
