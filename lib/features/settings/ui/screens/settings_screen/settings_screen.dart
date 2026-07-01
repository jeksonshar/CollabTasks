import 'package:collab_tasks/core/utils/auth_utils.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_bloc.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_event.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_state.dart';
import 'package:collab_tasks/features/auth/ui/profile_screen/profile_screen.dart';
import 'package:collab_tasks/features/settings/domain/models/theme_preference.dart';
import 'package:collab_tasks/features/settings/ui/blocs/locale_cubit/locale_cubit.dart';
import 'package:collab_tasks/features/settings/ui/blocs/theme_bloc/theme_bloc.dart';
import 'package:collab_tasks/features/settings/ui/blocs/theme_bloc/theme_event.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<String> _supportedLanguageCodes = ['en', 'ru', 'uk'];

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final selectedCode =
        context.watch<LocaleCubit>().state?.languageCode ??
        Localizations.localeOf(context).languageCode;
    final themeState = context.watch<ThemeBloc>().state;

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
                items: [
                  DropdownMenuItem(value: 'en', child: Text(localization.settingsLanguageEnglish)),
                  DropdownMenuItem(value: 'ru', child: Text(localization.settingsLanguageRussian)),
                  DropdownMenuItem(
                    value: 'uk',
                    child: Text(localization.settingsLanguageUkrainian),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  context.read<LocaleCubit>().changeLocale(value);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<AppThemeMode>(
                initialValue: themeState.themePreference.mode,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: localization.settingsTheme,
                ),
                items: [
                  DropdownMenuItem(
                    value: AppThemeMode.light,
                    child: Text(localization.settingsThemeLight),
                  ),
                  DropdownMenuItem(
                    value: AppThemeMode.dark,
                    child: Text(localization.settingsThemeDark),
                  ),
                  DropdownMenuItem(
                    value: AppThemeMode.system,
                    child: Text(localization.settingsThemeSystem),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  context.read<ThemeBloc>().add(ThemeModeChanged(ThemePreference(mode: value)));
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _onLogoutPressed(context, authState),
            icon: const Icon(Icons.logout),
            label: Text(localization.authLogOut),
          ),
        ],
      ),
    );
  }

  void _onLogoutPressed(BuildContext context, AuthState authState) {
    context.read<AuthBloc>().add(const AuthLogOutRequested());
    // костыль
    final localization = AppLocalizations.of(context)!;
    final user = authState.user;
    final authProviderLabel = mapProviderLabel(localization, user);

    if (authBackend == AuthBackend.aws && authProviderLabel == localization.authProviderGoogle) {
      Navigator.of(context).popUntil((route) => false);
    }
  }
}
