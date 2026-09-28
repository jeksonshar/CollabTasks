import 'package:collab_tasks/features/calls/domain/models/call_data_entity.dart';

abstract interface class CallKitService {
  Future<void> showIncomingCall(CallDataEntity callData);

  Future<void> endCall(String callId);

  Future<void> endAllCalls();
}
