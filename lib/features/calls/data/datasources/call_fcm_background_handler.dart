import 'dart:async';
import 'dart:convert';

import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/features/calls/domain/models/call_data_entity.dart';
import 'package:collab_tasks/features/calls/domain/services/call_kit_service.dart';
import 'package:collab_tasks/features/calls/domain/usecases/decline_incoming_call_usecase.dart';
import 'package:collab_tasks/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:shared_preferences/shared_preferences.dart';

const pendingCallKitAcceptPreferenceKey = 'pending_callkit_accept';
final StreamController<CallDataEntity> _callKitAcceptedActionController =
    StreamController<CallDataEntity>.broadcast();

Stream<CallDataEntity> get callKitAcceptedActions => _callKitAcceptedActionController.stream;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundCallHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  if (!getIt.isRegistered<CallKitService>()) {
    final preferences = await SharedPreferences.getInstance();
    setupLocator(preferences);
  }

  final data = message.data;
  final callKitService = getIt<CallKitService>();
  switch (data['action'] ?? data['type']) {
    case 'incoming_call':
      final callData = CallDataEntity.fromMap(data);
      if (callData.callId.isNotEmpty) {
        await callKitService.showIncomingCall(callData);
      }
      return;
    case 'cancel_call':
      final callId = (data['callId'] ?? data['id'])?.toString();
      if (callId != null && callId.isNotEmpty) {
        await callKitService.endCall(callId);
      }
      return;
  }
}

@pragma('vm:entry-point')
Future<void> callKitBackgroundEventHandler(CallEvent event) async {
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
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      pendingCallKitAcceptPreferenceKey,
      jsonEncode(_callDataMap(callData)),
    );
    return;
  }
  if (event is CallEventActionCallDecline) {
    final callData = _callDataFromParams(event.callKitParams);
    if (callData.calleeId.isEmpty) {
      debugPrint('[CallKitBackground] Cannot reject call without calleeId');
      return;
    }
    await getIt<DeclineIncomingCallUseCase>().call(
      callId: callData.callId,
      userId: callData.calleeId,
    );
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
