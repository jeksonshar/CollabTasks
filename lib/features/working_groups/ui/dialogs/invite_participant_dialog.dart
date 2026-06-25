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
    return AlertDialog(
      title: const Text('Пригласить участника'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Введите email';
            // Сюда можно добавить regex валидацию email
            return null;
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_emailController.text.trim());
            }
          },
          child: const Text('Пригласить'),
        ),
      ],
    );
  }
}
