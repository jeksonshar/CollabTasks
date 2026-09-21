class AgoraConfig {
  /// Agora App ID. Defaults to environment variable or mock/placeholder for development.
  static const String appId = String.fromEnvironment(
    'AGORA_APP_ID',
    // defaultValue: 'test_agora_app_id',
    defaultValue: '3346094ab83e471380d0d501626c2415',
  );
}
