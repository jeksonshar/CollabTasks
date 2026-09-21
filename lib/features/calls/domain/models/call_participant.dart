import 'package:equatable/equatable.dart';

enum CallParticipantRole { host, participant }

enum CallParticipantStatus { invited, ringing, connected, declined, left }

class CallParticipant extends Equatable {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final CallParticipantRole role;
  final CallParticipantStatus status;
  final DateTime? joinedAt;

  const CallParticipant({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.role = CallParticipantRole.participant,
    this.status = CallParticipantStatus.invited,
    this.joinedAt,
  });

  CallParticipant copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    CallParticipantRole? role,
    CallParticipantStatus? status,
    DateTime? joinedAt,
  }) {
    return CallParticipant(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'role': role.name,
      'status': status.name,
      'joinedAtMillis': joinedAt?.millisecondsSinceEpoch,
    };
  }

  factory CallParticipant.fromMap(Map<String, dynamic> map) {
    return CallParticipant(
      userId: map['userId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
      role: CallParticipantRole.values.byName(
        map['role'] as String? ?? CallParticipantRole.participant.name,
      ),
      status: CallParticipantStatus.values.byName(
        map['status'] as String? ?? CallParticipantStatus.invited.name,
      ),
      joinedAt: map['joinedAtMillis'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['joinedAtMillis'] as num).toInt())
          : null,
    );
  }

  @override
  List<Object?> get props => [userId, displayName, avatarUrl, role, status, joinedAt];
}
