import 'dart:convert';

import 'package:collab_tasks/l10n/l10n_mixin.dart';
import 'package:collab_tasks/ui/dialogs/task_dialog/ui_components/task_attachments_section.dart';
import 'package:collab_tasks/ui/dialogs/task_dialog/ui_components/task_completed_section.dart';
import 'package:collab_tasks/ui/dialogs/task_dialog/ui_components/task_deadline_section.dart';
import 'package:collab_tasks/ui/dialogs/task_dialog/ui_components/task_formatter_editor_section.dart';
import 'package:collab_tasks/ui/dialogs/task_dialog/ui_components/task_priority_section.dart';
import 'package:collab_tasks/ui/dialogs/task_dialog/ui_components/task_title_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../../core/task_priority/task_priority_utils.dart';
import '../../../domain/models/task_attachment.dart';
import '../../../domain/models/task_draft.dart';
import '../../screens/home_screen/utils/json_helpers.dart';

class TaskDialog extends StatefulWidget {
  final String? initialTitle;
  final String? initialDeltaJson;
  final List<TaskAttachment> initialAttachments;
  final int initialPriority;
  final bool initialIsCompletedState;
  final DateTime? initialDeadline;

  const TaskDialog({
    super.key,
    this.initialTitle,
    this.initialDeltaJson,
    this.initialAttachments = const [],
    this.initialPriority = 0,
    this.initialIsCompletedState = false,
    this.initialDeadline,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> with L10nMixin {
  late quill.QuillController _controller;
  late TextEditingController _titleController;

  final FocusNode _focusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  final GlobalKey _editorKey = GlobalKey();

  final List<TaskAttachment> _attachments = [];
  int _priority = 0;
  bool _isCompleted = false;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _controller = _createController(widget.initialDeltaJson);
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _attachments.addAll(widget.initialAttachments);
    _priority = widget.initialPriority;
    _isCompleted = widget.initialIsCompletedState;
    _deadline = widget.initialDeadline;
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

    if (oldWidget.initialIsCompletedState != widget.initialIsCompletedState) {
      _isCompleted = widget.initialIsCompletedState;
    }

    if (oldWidget.initialDeadline != widget.initialDeadline) {
      _deadline = widget.initialDeadline;
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

  bool get _isEmpty =>
      _titleController.text.trim().isEmpty || _controller.document.toPlainText().trim().isEmpty;

  void _submit() {
    if (_isEmpty) return;

    final trimmedDelta = trimDelta(_controller.document.toDelta());

    Navigator.of(context).pop(
      TaskDraft(
        title: _titleController.text.trim(),
        textJson: jsonEncode(trimmedDelta.toJson()),
        priority: _priority,
        isCompleted: _isCompleted,
        attachments: List.unmodifiable(_attachments),
        deadline: _deadline,
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

  void onIsTaskCompleteChanged(bool value) {
    setState(() {
      _isCompleted = value;
    });
  }

  void _onDeadlineChanged(DateTime? newDeadline) {
    setState(() {
      _deadline = newDeadline;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
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
              // Title input field
              TaskTitleSection(controller: _titleController),
              const SizedBox(height: 8),
              TaskFormatterEditorSection(
                editorKey: _editorKey,
                controller: _controller,
                focusNode: _focusNode,
                scrollController: _editorScrollController,
                formattingTitle: localization.formattingTitle,
                editorPlaceholder: localization.editorPlaceholder,
              ),
              const SizedBox(height: 4),
              TaskDeadlineSection(initialDeadline: _deadline, onChanged: _onDeadlineChanged),
              if (isEdit) ...[
                TaskCompletedSection(
                  title: localization.completedTaskTitle,
                  isCompleted: _isCompleted,
                  onChanged: onIsTaskCompleteChanged,
                ),
              ],
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
          animation: Listenable.merge([_controller, _titleController]),
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
