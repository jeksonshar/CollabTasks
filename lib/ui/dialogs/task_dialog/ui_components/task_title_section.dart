import 'package:flutter/material.dart';
import 'package:task_manager/l10n/app_localizations.dart';

class TaskTitleSection extends StatelessWidget {
  final TextEditingController controller;

  const TaskTitleSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔹 Label for title
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            localization.titleField,
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ),

        /// 🔹 Title
        TextField(
          controller: controller,
          minLines: 1,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: localization.titlePlaceholder,
            hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}
