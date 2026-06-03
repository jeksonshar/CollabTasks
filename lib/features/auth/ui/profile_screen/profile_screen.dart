import 'package:collab_tasks/core/utils/auth_utils.dart';
import 'package:collab_tasks/features/auth/ui/auth_bloc/auth_bloc.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;

    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : localization.authNameNotProvided;
    final email = (user?.email.trim().isNotEmpty ?? false)
        ? user!.email.trim()
        : localization.authNameNotProvided;
    final authProviderLabel = mapProviderLabel(localization, user);

    return Scaffold(
      appBar: AppBar(title: Text(localization.profile), centerTitle: false),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade200,
                child: Icon(Icons.person, size: 50, color: Colors.blue.shade800),
              ),
              const SizedBox(height: 24),
              Text(
                localization.userProfile,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileField(localization.nameTitle, displayName),
                      const Divider(),
                      _buildProfileField(localization.emailTitle, email),
                      const Divider(),
                      _buildProfileField(localization.authProviderTitle, authProviderLabel),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localization.profileScreenEditProfileFunctionality)),
                  );
                },
                icon: const Icon(Icons.edit),
                label: Text(localization.editProfile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
