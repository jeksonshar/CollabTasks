import 'package:collab_tasks/features/calls/domain/models/call_data_entity.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:collab_tasks/features/calls/domain/services/call_kit_service.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

class CallKitServiceImpl implements CallKitService {
  const CallKitServiceImpl();

  @override
  Future<void> showIncomingCall(CallDataEntity callData) async {
    await FlutterCallkitIncoming.showCallkitIncoming(
      CallKitParams(
        id: callData.callId,
        nameCaller: callData.displayName,
        handle: callData.handle,
        type: callData.callType == CallType.video ? 1 : 0,
        duration: 30000,
        extra: {
          'callId': callData.callId,
          'displayName': callData.displayName,
          'handle': callData.handle,
          'agoraChannel': callData.agoraChannel,
          'token': callData.token,
          'callerId': callData.callerId,
          'calleeId': callData.calleeId,
          'callType': callData.callType.name,
          'isGroup': callData.isGroup,
        },
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          isShowFullLockedScreen: true,
          ringtonePath: 'system_ringtone_default',
        ),
      ),
    );
  }

  @override
  Future<void> endCall(String callId) async {
    await FlutterCallkitIncoming.endCall(callId);
    await FlutterCallkitIncoming.hideCallkitIncoming(
      CallKitParams(id: callId, nameCaller: '', handle: ''),
    );
  }

  @override
  Future<void> endAllCalls() async {
    await FlutterCallkitIncoming.endAllCalls();
  }
}
