import 'package:collab_tasks/features/auth/domain/entities/auth_user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.email,
    required super.isEmailVerified,
    super.displayName,
    required super.provider,
  });

  factory AuthUserModel.fromFirebaseUser(firebase_auth.User user) {
    final provider = _resolveProvider(user);
    return AuthUserModel(
      id: user.uid,
      email: user.email ?? '',
      isEmailVerified: user.emailVerified,
      displayName: user.displayName,
      provider: provider,
    );
  }

  static AuthProviderType _resolveProvider(firebase_auth.User user) {
    final providerIds = user.providerData.map((provider) => provider.providerId).toSet();
    if (providerIds.contains('google.com')) {
      return AuthProviderType.google;
    }
    if (providerIds.contains('password')) {
      return AuthProviderType.email;
    }
    return AuthProviderType.unknown;
  }
}
