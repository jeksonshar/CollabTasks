import 'package:equatable/equatable.dart';

class CallSession extends Equatable {
  final String callId;
  final String roomId;
  final String token;
  final String localUserId;
  final Map<String, dynamic> extra;

  const CallSession({
    required this.callId,
    required this.roomId,
    required this.token,
    required this.localUserId,
    this.extra = const {},
  });

  CallSession copyWith({
    String? callId,
    String? roomId,
    String? token,
    String? localUserId,
    Map<String, dynamic>? extra,
  }) {
    return CallSession(
      callId: callId ?? this.callId,
      roomId: roomId ?? this.roomId,
      token: token ?? this.token,
      localUserId: localUserId ?? this.localUserId,
      extra: extra ?? this.extra,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'roomId': roomId,
      'token': token,
      'localUserId': localUserId,
      'extra': extra,
    };
  }

  factory CallSession.fromMap(Map<String, dynamic> map) {
    return CallSession(
      callId: map['callId'] as String? ?? '',
      roomId: map['roomId'] as String? ?? '',
      token: map['token'] as String? ?? '',
      localUserId: map['localUserId'] as String? ?? '',
      extra: Map<String, dynamic>.from((map['extra'] as Map?) ?? const {}),
    );
  }

  @override
  List<Object?> get props => [callId, roomId, token, localUserId, extra];
}
