import 'package:equatable/equatable.dart';

enum AuthProviderType { email, google, unknown }

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    required this.isEmailVerified,
    this.displayName,
    this.provider = AuthProviderType.unknown,
  });

  final String id;
  final String email;
  final bool isEmailVerified;
  final String? displayName;
  final AuthProviderType provider;

  @override
  List<Object?> get props => [id, email, isEmailVerified, displayName, provider];
}
