import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:collab_tasks/ui/blocs/auth_bloc/auth_bloc.dart';
import 'package:collab_tasks/ui/blocs/auth_bloc/auth_event.dart';
import 'package:collab_tasks/ui/blocs/locale_cubit/locale_cubit.dart';
import 'package:collab_tasks/ui/screens/profile_screen/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<String> _supportedLanguageCodes = ['en', 'ru', 'uk'];

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final selectedCode =
        context.watch<LocaleCubit>().state?.languageCode ??
        Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(localization.settings), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(localization.profile),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<String>(
                initialValue: _supportedLanguageCodes.contains(selectedCode) ? selectedCode : 'en',
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: localization.language,
                ),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'ru', child: Text('Russian')),
                  DropdownMenuItem(value: 'uk', child: Text('Ukrainian')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  context.read<LocaleCubit>().changeLocale(value);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.read<AuthBloc>().add(const AuthLogOutRequested()),
            icon: const Icon(Icons.logout),
            label: Text(localization.authLogOut),
          ),
        ],
      ),
    );
  }
}
