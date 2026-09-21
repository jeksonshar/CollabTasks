import 'package:collab_tasks/features/calls/domain/services/call_permissions_service.dart';
import 'package:permission_handler/permission_handler.dart';

class CallPermissionsServiceImpl implements CallPermissionsService {
  const CallPermissionsServiceImpl();

  @override
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  @override
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  @override
  Future<bool> checkMicrophonePermission() async {
    return Permission.microphone.isGranted;
  }

  @override
  Future<bool> checkCameraPermission() async {
    return Permission.camera.isGranted;
  }
}
