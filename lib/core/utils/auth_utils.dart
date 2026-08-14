import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';

enum AuthBackend { aws, firebase }

enum StorageBackend { aws, firebase }

enum ChatBackend { webSocket, firebase }

const AuthBackend authBackend = AuthBackend.firebase;

StorageBackend get storageBackend => switch (authBackend) {
  AuthBackend.aws => StorageBackend.aws,
  AuthBackend.firebase => StorageBackend.firebase,
};

ChatBackend get chatBackend => switch (authBackend) {
  AuthBackend.aws => ChatBackend.webSocket,
  AuthBackend.firebase => ChatBackend.webSocket,
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
