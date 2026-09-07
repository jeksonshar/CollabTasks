import 'package:flutter/material.dart';

/// Opaque cover shown when the app goes to the OS task switcher (backgrounded).
///
/// Prevents sensitive task data from being captured in OS screenshots or
/// appearing in the recent apps thumbnails.
class PrivacyScreenWidget extends StatelessWidget {
  const PrivacyScreenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 64, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'CollabTasks',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
