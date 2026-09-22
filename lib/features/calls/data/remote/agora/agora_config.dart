class AgoraConfig {
  /// Agora App ID. Set via --dart-define=AGORA_APP_ID=<value>.
  static const String appId = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: '3346094ab83e471380d0d501626c2415',
  );

  /// Agora App Certificate. Set via --dart-define=AGORA_APP_CERTIFICATE=<value>.
  /// Required for AccessToken2 generation.
  static const String appCertificate = String.fromEnvironment(
    'AGORA_APP_CERTIFICATE',
    defaultValue: '',
  );

  /// Firebase Cloud Function URL for token generation.
  /// Format: https://<region>-<project-id>.cloudfunctions.net/getAgoraRtcToken
  static const String tokenServerUrl = String.fromEnvironment(
    'AGORA_TOKEN_SERVER_URL',
    defaultValue: 'https://us-central1-collabtasks-fda3f.cloudfunctions.net/getAgoraRtcToken',
  );

  /// Token expiry in seconds (24 hours).
  static const int tokenExpirySeconds = 86400;
}
