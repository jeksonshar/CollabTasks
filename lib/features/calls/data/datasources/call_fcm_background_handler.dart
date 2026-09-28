import 'dart:async';
import 'dart:convert';

import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/calls/domain/models/call_data_entity.dart';
import 'package:collab_tasks/features/calls/domain/services/call_kit_service.dart';
import 'package:collab_tasks/features/calls/domain/usecases/decline_incoming_call_usecase.dart';
import 'package:collab_tasks/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:shared_preferences/shared_preferences.dart';

const pendingCallKitAcceptPreferenceKey = 'pending_callkit_accept';
const pendingCallKitDeclinePreferenceKey = 'pending_callkit_decline';
final StreamController<CallDataEntity> _callKitAcceptedActionController =
    StreamController<CallDataEntity>.broadcast();

Stream<CallDataEntity> get callKitAcceptedActions => _callKitAcceptedActionController.stream;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundCallHandler(RemoteMessage message) async {
  final data = message.data;
  final action = data['action'] ?? data['type'];
  debugPrint('[FCMCall] Background message received: id=${message.messageId}, action=$action');

  try {
    WidgetsFlutterBinding.ensureInitialized();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
    if (!getIt.isRegistered<CallKitService>()) {
      final preferences = await SharedPreferences.getInstance();
      setupLocator(preferences);
    }

    // FCM may start a fresh Android process for the incoming push. In that
    // process main() has not registered CallKit's separate action engine, so
    // the native Decline button would only dismiss Telecom UI without reaching
    // Dart. Register the callback from this engine before presenting the call.
    await FlutterCallkitIncoming.onBackgroundMessage(callKitBackgroundEventHandler);
    debugPrint('[FCMCall] CallKit background action handler registered');

    final callKitService = getIt<CallKitService>();
    switch (action) {
      case 'incoming_call':
        final callData = CallDataEntity.fromMap(data);
        if (callData.callId.isEmpty) {
          debugPrint('[FCMCall] Incoming call message has no callId');
          return;
        }
        await callKitService.showIncomingCall(callData);
        debugPrint('[FCMCall] CallKit incoming UI shown for ${callData.callId}');
        return;
      case 'cancel_call':
        final callId = (data['callId'] ?? data['id'])?.toString();
        if (callId != null && callId.isNotEmpty) {
          await callKitService.endCall(callId);
          debugPrint('[FCMCall] CallKit UI dismissed for $callId');
        } else {
          debugPrint('[FCMCall] Cancel message has no callId');
        }
        return;
      default:
        debugPrint('[FCMCall] Ignored unsupported background action: $action');
    }
  } catch (error, stackTrace) {
    debugPrint('[FCMCall] Background handler failed: $error\n$stackTrace');
  }
}

@pragma('vm:entry-point')
Future<void> callKitBackgroundEventHandler(CallEvent event) async {
  debugPrint('[CallKitBackground] Native action received: ${event.runtimeType}');
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  if (!getIt.isRegistered<CallKitService>()) {
    final preferences = await SharedPreferences.getInstance();
    setupLocator(preferences);
  }

  if (event is CallEventActionCallAccept) {
    final callData = _callDataFromParams(event.callKitParams);
    if (callData.callId.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      pendingCallKitAcceptPreferenceKey,
      jsonEncode(_callDataMap(callData)),
    );
    return;
  }
  if (event is CallEventActionCallDecline) {
    final callData = _callDataFromParams(event.callKitParams);
    if (callData.callId.isEmpty) return;
    debugPrint('[CallKitBackground] Processing decline for ${callData.callId}');
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      pendingCallKitDeclinePreferenceKey,
      jsonEncode(_callDataMap(callData)),
    );
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentEmail = currentUser?.email;
    final userId = callData.calleeId.trim().isNotEmpty
        ? callData.calleeId.trim()
        : (currentEmail != null && currentEmail.isNotEmpty ? currentEmail : currentUser?.uid ?? '');
    if (userId.isEmpty) {
      debugPrint('[CallKitBackground] Cannot reject call without calleeId');
      return;
    }
    try {
      await getIt<DeclineIncomingCallUseCase>().call(callId: callData.callId, userId: userId);
      await preferences.remove(pendingCallKitDeclinePreferenceKey);
      debugPrint('[CallKitBackground] Decline persisted for ${callData.callId}');
    } catch (error, stackTrace) {
      debugPrint('[CallKitBackground] Decline will be retried on app resume: $error\n$stackTrace');
    }
    return;
  }
  if (event is CallEventActionCallTimeout) {
    await getIt<CallKitService>().endCall(event.id);
    return;
  }
}

CallDataEntity _callDataFromParams(CallKitParams params) => CallDataEntity.fromMap({
  ...?params.extra,
  'callId': params.id,
  'displayName': params.nameCaller,
  'handle': params.handle,
  'callType': params.type?.toString() ?? '0',
});

Map<String, Object?> _callDataMap(CallDataEntity callData) => {
  'callId': callData.callId,
  'displayName': callData.displayName,
  'handle': callData.handle,
  'agoraChannel': callData.agoraChannel,
  'token': callData.token,
  'callerId': callData.callerId,
  'calleeId': callData.calleeId,
  'callerAvatarUrl': callData.callerAvatarUrl,
  'callType': callData.callType.name,
  'isGroup': callData.isGroup,
};

@pragma('vm:entry-point')
void callKitAcceptedFromKilledHandler(Map<dynamic, dynamic> body) {
  final callData = CallDataEntity.fromMap(Map<String, dynamic>.from(body));
  if (callData.callId.isEmpty) return;
  _callKitAcceptedActionController.add(callData);
  unawaited(_persistAcceptedCall(callData));
}

Future<void> _persistAcceptedCall(CallDataEntity callData) async {
  final preferences = await SharedPreferences.getInstance();
  await preferences.setString(
    pendingCallKitAcceptPreferenceKey,
    jsonEncode(_callDataMap(callData)),
  );
}
