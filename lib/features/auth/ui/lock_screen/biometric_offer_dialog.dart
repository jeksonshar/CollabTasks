import 'package:collab_tasks/features/auth/ui/lock_bloc/lock_bloc.dart';
import 'package:collab_tasks/features/auth/ui/lock_bloc/lock_event.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Dialog shown after a successful login when the device supports biometrics
/// and the user has not yet configured biometric login.
///
/// Dispatches [LockBiometricOfferResponded] to [LockBloc]; no business logic here.
class BiometricOfferDialog extends StatelessWidget {
  const BiometricOfferDialog({super.key});

  /// Shows this dialog. Returns after the user responds.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          BlocProvider.value(value: context.read<LockBloc>(), child: const BiometricOfferDialog()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      icon: const Icon(Icons.fingerprint, size: 40),
      title: Text(l10n.biometricOfferTitle),
      content: Text(l10n.biometricOfferDescription),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.read<LockBloc>().add(const LockBiometricOfferResponded(accepted: false));
          },
          child: Text(l10n.biometricOfferSkip),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.read<LockBloc>().add(const LockBiometricOfferResponded(accepted: true));
          },
          child: Text(l10n.biometricOfferEnable),
        ),
      ],
    );
  }
}
