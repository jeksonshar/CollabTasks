import 'package:collab_tasks/features/auth/ui/lock_bloc/lock_bloc.dart';
import 'package:collab_tasks/features/auth/ui/lock_bloc/lock_event.dart';
import 'package:collab_tasks/features/auth/ui/lock_bloc/lock_state.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Full-screen overlay shown when the app is locked.
///
/// Renders over all other content. The user may:
/// - Tap "Unlock" to trigger biometric authentication again.
/// - Tap "Sign in with password" to logout and return to the auth screen.
///
/// All interactions dispatch events to [LockBloc]; no business logic lives here.
class LockScreenWidget extends StatelessWidget {
  const LockScreenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<LockBloc>().state;
    final isAuthenticating = state.status == LockStatus.authenticating;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 72),
                const SizedBox(height: 24),
                Text(
                  l10n.biometricLockTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                if (isAuthenticating)
                  const CircularProgressIndicator()
                else ...[
                  FilledButton.icon(
                    onPressed: () =>
                        context.read<LockBloc>().add(const LockAuthenticateRequested()),
                    icon: const Icon(Icons.fingerprint),
                    label: Text(l10n.biometricUnlockButton),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () =>
                        context.read<LockBloc>().add(const LockSignInWithPasswordRequested()),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: Text(l10n.biometricLoginWithPassword),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
