import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:task_manager/l10n/l10n_mixin.dart';
import 'package:task_manager/ui/dialogs/task_dialog/ui_components/task_attachments_section.dart';
import 'package:task_manager/ui/dialogs/task_dialog/ui_components/task_formatter_editor_section.dart';
import 'package:task_manager/ui/dialogs/task_dialog/ui_components/task_priority_section.dart';

import '../../../core/task_priority/task_priority_utils.dart';
import '../../../domain/models/task_attachment.dart';
import '../../../domain/models/task_draft.dart';
import '../../screens/home_screen/utils/json_helpers.dart';

class TaskDialog extends StatefulWidget {
  final String? initialDeltaJson;
  final List<TaskAttachment> initialAttachments;
  final int initialPriority;

  const TaskDialog({
    super.key,
    this.initialDeltaJson,
    this.initialAttachments = const [],
    this.initialPriority = 0,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> with L10nMixin {
  late quill.QuillController _controller;

  final FocusNode _focusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  final GlobalKey _editorKey = GlobalKey();

  final List<TaskAttachment> _attachments = [];
  int _priority = 0;

  @override
  void initState() {
    super.initState();
    _controller = _createController(widget.initialDeltaJson);
    _attachments.addAll(widget.initialAttachments);
    _priority = widget.initialPriority;
  }

  @override
  void didUpdateWidget(covariant TaskDialog oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialDeltaJson != widget.initialDeltaJson) {
      _controller.dispose();
      _controller = _createController(widget.initialDeltaJson);
    }

    if (oldWidget.initialPriority != widget.initialPriority) {
      _priority = widget.initialPriority;
    }
  }

  quill.QuillController _createController(String? initialDeltaJson) {
    if (initialDeltaJson != null) {
      try {
        final doc = quill.Document.fromJson(jsonDecode(initialDeltaJson) as List<dynamic>);

        return quill.QuillController(
          document: doc,
          selection: TextSelection.collapsed(offset: doc.length > 0 ? doc.length - 1 : 0),
        );
      } catch (_) {
        final doc = quill.Document()..insert(0, initialDeltaJson);
        return quill.QuillController(
          document: doc,
          selection: TextSelection.collapsed(offset: doc.length),
        );
      }
    }

    return quill.QuillController.basic();
  }

  bool get _isEmpty => _controller.document.toPlainText().trim().isEmpty;

  void _submit() {
    if (_isEmpty) return;

    final trimmedDelta = trimDelta(_controller.document.toDelta());

    Navigator.of(context).pop(
      TaskDraft(
        textJson: jsonEncode(trimmedDelta.toJson()),
        priority: _priority,
        attachments: List.unmodifiable(_attachments),
      ),
    );
  }

  void _onAttachmentsChanged(List<TaskAttachment> list) {
    _attachments
      ..clear()
      ..addAll(list);
  }

  void _onPriorityChanged(TaskPriority newPriority) {
    setState(() {
      _priority = newPriority.value;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _editorScrollController.dispose();
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
              const SizedBox(height: 4),
              TaskPrioritySection(
                title: localization.priorityTitle,
                priority: TaskPriority.fromValue(_priority),
                onChanged: _onPriorityChanged,
              ),
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
            return ElevatedButton(
              onPressed: _isEmpty ? null : _submit,
              child: Text(isEdit ? localization.update : localization.enter),
            );
          },
        ),
      ],
    );
  }
}
