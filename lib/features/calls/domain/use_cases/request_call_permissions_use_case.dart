import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:collab_tasks/features/calls/domain/services/call_permissions_service.dart';

class RequestCallPermissionsUseCase {
  final CallPermissionsService _permissionsService;

  const RequestCallPermissionsUseCase(this._permissionsService);

  /// Requests required permissions for the given [CallType].
  /// Returns true if all required permissions are granted, false otherwise.
  Future<bool> call({required CallType type}) async {
    final micGranted = await _permissionsService.requestMicrophonePermission();
    if (!micGranted) {
      return false;
    }

    if (type == CallType.video) {
      final cameraGranted = await _permissionsService.requestCameraPermission();
      if (!cameraGranted) {
        return false;
      }
    }

    return true;
  }
}
