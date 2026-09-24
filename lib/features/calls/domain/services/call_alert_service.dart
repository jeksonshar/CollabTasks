/// Contract for call-related audible and haptic alerts.
abstract class CallAlertService {
  /// Starts the looping tone played while an outgoing call is ringing.
  Future<void> startOutgoingRingtone();

  /// Starts the looping ringtone and vibration for an incoming call.
  Future<void> startIncomingRingtone();

  /// Stops any active ringtone and vibration.
  Future<void> stop();

  /// Releases resources owned by this service.
  void dispose();
}
