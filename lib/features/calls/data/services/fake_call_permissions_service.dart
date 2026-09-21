import 'package:collab_tasks/features/calls/domain/services/call_permissions_service.dart';

/// Fake implementation of [CallPermissionsService] for tests and mocks.
class FakeCallPermissionsService implements CallPermissionsService {
  bool microphoneGranted;
  bool cameraGranted;

  FakeCallPermissionsService({this.microphoneGranted = true, this.cameraGranted = true});

  @override
  Future<bool> requestMicrophonePermission() async => microphoneGranted;

  @override
  Future<bool> requestCameraPermission() async => cameraGranted;

  @override
  Future<bool> checkMicrophonePermission() async => microphoneGranted;

  @override
  Future<bool> checkCameraPermission() async => cameraGranted;
}
