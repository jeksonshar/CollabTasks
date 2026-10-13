import 'package:collab_tasks/features/calls/domain/models/call_type.dart';

/// Minimal call data needed to present an incoming call through the OS UI.
class CallDataEntity {
  final String callId;
  final String displayName;
  final String handle;
  final String agoraChannel;
  final String token;
  final String callerId;
  final String calleeId;
  final String? callerAvatarUrl;
  final CallType callType;
  final bool isGroup;

  const CallDataEntity({
    required this.callId,
    required this.displayName,
    required this.handle,
    required this.agoraChannel,
    required this.token,
    required this.callerId,
    this.calleeId = '',
    this.callerAvatarUrl,
    required this.callType,
    this.isGroup = false,
  });

  CallDataEntity copyWith({
    String? callId,
    String? displayName,
    String? handle,
    String? agoraChannel,
    String? token,
    String? callerId,
    String? calleeId,
    String? callerAvatarUrl,
    CallType? callType,
    bool? isGroup,
  }) {
    return CallDataEntity(
      callId: callId ?? this.callId,
      displayName: displayName ?? this.displayName,
      handle: handle ?? this.handle,
      agoraChannel: agoraChannel ?? this.agoraChannel,
      token: token ?? this.token,
      callerId: callerId ?? this.callerId,
      calleeId: calleeId ?? this.calleeId,
      callerAvatarUrl: callerAvatarUrl ?? this.callerAvatarUrl,
      callType: callType ?? this.callType,
      isGroup: isGroup ?? this.isGroup,
    );
  }

  factory CallDataEntity.fromMap(Map<String, dynamic> data) {
    final rawType = data['callType']?.toString().toLowerCase();
    return CallDataEntity(
      callId: (data['callId'] ?? data['id'] ?? '').toString(),
      displayName: (data['displayName'] ?? data['callerName'] ?? 'Unknown caller').toString(),
      handle: (data['handle'] ?? data['phone'] ?? data['email'] ?? '').toString(),
      agoraChannel: (data['agoraChannel'] ?? '').toString(),
      token: (data['token'] ?? '').toString(),
      callerId: (data['callerId'] ?? '').toString(),
      calleeId: (data['calleeId'] ?? '').toString(),
      callerAvatarUrl: data['callerAvatarUrl']?.toString() ?? data['avatar']?.toString(),
      callType: rawType == 'video' || rawType == '1' ? CallType.video : CallType.audio,
      isGroup: data['isGroup'] == true || data['isGroup']?.toString() == 'true',
    );
  }
}
