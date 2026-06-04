import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';

enum AuthBackend { aws, firebase }

const AuthBackend authBackend = AuthBackend.firebase;

enum StorageBackend { aws, firebase }

StorageBackend get storageBackend => switch (authBackend) {
  AuthBackend.aws => StorageBackend.aws,
  AuthBackend.firebase => StorageBackend.firebase,
};

String mapProviderLabel(AppLocalizations localization, AuthUser? user) {
  switch (user?.provider) {
    case AuthProviderType.google:
      return localization.authProviderGoogle;
    case AuthProviderType.email:
      return localization.authProviderEmail;
    case AuthProviderType.unknown:
    case null:
      return localization.authProviderUnknown;
  }
}
