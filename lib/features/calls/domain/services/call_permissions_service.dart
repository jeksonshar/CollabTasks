/// Provider-independent contract for checking and requesting call media permissions.
abstract class CallPermissionsService {
  /// Requests microphone recording permission. Returns true if granted.
  Future<bool> requestMicrophonePermission();

  /// Requests camera recording permission. Returns true if granted.
  Future<bool> requestCameraPermission();

  /// Checks whether microphone permission is currently granted.
  Future<bool> checkMicrophonePermission();

  /// Checks whether camera permission is currently granted.
  Future<bool> checkCameraPermission();
}
