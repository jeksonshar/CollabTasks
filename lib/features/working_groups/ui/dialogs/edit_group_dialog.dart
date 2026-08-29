import 'dart:convert';

import 'package:collab_tasks/features/working_groups/domain/models/working_group.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

typedef EditGroupResult = ({String title, String description, String? avatarUrl});

class EditGroupDialog extends StatefulWidget {
  const EditGroupDialog({super.key, required this.group});

  final WorkingGroup group;

  @override
  State<EditGroupDialog> createState() => _EditGroupDialogState();
}

class _EditGroupDialogState extends State<EditGroupDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.group.title);
    _descriptionController = TextEditingController(text: widget.group.description);
    _avatarUrl = widget.group.avatarUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final List<PlatformFile> files = await FilePicker.pickFiles(
      type: FileType.image,
    );

    if (files.isEmpty) return;

    final file = files.first;
    final bytes = await file.readAsBytes();

    final extension = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : '';

    final mime = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/png',
    };

    if (mounted) {
      setState(() {
        _avatarUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(localization.edit_group_dialog_title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundImage: switch (widget.group.copyWith(avatarUrl: _avatarUrl).avatarSource) {
                NetworkAvatar(:final url) => NetworkImage(url),
                MemoryAvatar(:final bytes) => MemoryImage(bytes),
                DefaultAvatar() => null,
              },
              child: _avatarUrl == null ? const Icon(Icons.groups, size: 36) : null,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _pickAvatar,
              icon: const Icon(Icons.image),
              label: Text(localization.edit_group_dialog_changeAvatarBtn),
            ),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: localization.edit_group_dialog_textFieldName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: localization.edit_group_dialog_textFieldDesctiption,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localization.edit_group_dialog_cancelBtn),
        ),
        ElevatedButton(
          onPressed: () {
            final title = _titleController.text.trim();
            if (title.isEmpty) return;
            Navigator.of(context).pop((
              title: title,
              description: _descriptionController.text.trim(),
              avatarUrl: _avatarUrl,
            ));
          },
          child: Text(localization.edit_group_dialog_saveBtn),
        ),
      ],
    );
  }
}
