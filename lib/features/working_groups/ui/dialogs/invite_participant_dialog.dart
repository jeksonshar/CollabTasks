import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class InviteParticipantDialog extends StatefulWidget {
  const InviteParticipantDialog({super.key});

  @override
  State<InviteParticipantDialog> createState() => _InviteParticipantDialogState();
}

class _InviteParticipantDialogState extends State<InviteParticipantDialog> {
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(localization.invite_participant_dialog_title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: localization.invite_participant_dialog_textFieldDecorationEmail,
          ),
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return localization.invite_participant_dialog_textFieldValidator;
            }
            // Сюда можно добавить regex валидацию email
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localization.invite_participant_dialog_cancelBtn),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_emailController.text.trim());
            }
          },
          child: Text(localization.invite_participant_dialog_inviteBtn),
        ),
      ],
    );
  }
}
