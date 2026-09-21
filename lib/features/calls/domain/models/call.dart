import 'package:collab_tasks/features/calls/domain/models/call_participant.dart';
import 'package:collab_tasks/features/calls/domain/models/call_status.dart';
import 'package:collab_tasks/features/calls/domain/models/call_type.dart';
import 'package:equatable/equatable.dart';

class Call extends Equatable {
  final String id;
  final String callerId;
  final String callerName;
  final String? callerAvatarUrl;
  final List<String> calleeIds;
  final CallType type;
  final CallStatus status;
  final bool isGroup;
  final String? groupId;
  final List<CallParticipant> participants;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const Call({
    required this.id,
    required this.callerId,
    required this.callerName,
    this.callerAvatarUrl,
    required this.calleeIds,
    required this.type,
    required this.status,
    this.isGroup = false,
    this.groupId,
    this.participants = const [],
    required this.createdAt,
    this.startedAt,
    this.endedAt,
  });

  Call copyWith({
    String? id,
    String? callerId,
    String? callerName,
    String? callerAvatarUrl,
    List<String>? calleeIds,
    CallType? type,
    CallStatus? status,
    bool? isGroup,
    String? groupId,
    List<CallParticipant>? participants,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return Call(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerAvatarUrl: callerAvatarUrl ?? this.callerAvatarUrl,
      calleeIds: calleeIds ?? this.calleeIds,
      type: type ?? this.type,
      status: status ?? this.status,
      isGroup: isGroup ?? this.isGroup,
      groupId: groupId ?? this.groupId,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'callerId': callerId,
      'callerName': callerName,
      'callerAvatarUrl': callerAvatarUrl,
      'calleeIds': calleeIds,
      'type': type.name,
      'status': status.name,
      'isGroup': isGroup,
      'groupId': groupId,
      'participants': participants.map((p) => p.toMap()).toList(),
      'createdAtMillis': createdAt.millisecondsSinceEpoch,
      'startedAtMillis': startedAt?.millisecondsSinceEpoch,
      'endedAtMillis': endedAt?.millisecondsSinceEpoch,
    };
  }

  factory Call.fromMap(Map<String, dynamic> map) {
    return Call(
      id: map['id'] as String? ?? '',
      callerId: map['callerId'] as String? ?? '',
      callerName: map['callerName'] as String? ?? '',
      callerAvatarUrl: map['callerAvatarUrl'] as String?,
      calleeIds: List<String>.from((map['calleeIds'] as Iterable?) ?? const []),
      type: CallType.values.byName(map['type'] as String? ?? CallType.audio.name),
      status: CallStatus.values.byName(map['status'] as String? ?? CallStatus.initiating.name),
      isGroup: map['isGroup'] as bool? ?? false,
      groupId: map['groupId'] as String?,
      participants: ((map['participants'] as Iterable?) ?? const [])
          .map((p) => CallParticipant.fromMap(p as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAtMillis'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
      startedAt: map['startedAtMillis'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['startedAtMillis'] as num).toInt())
          : null,
      endedAt: map['endedAtMillis'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['endedAtMillis'] as num).toInt())
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    callerId,
    callerName,
    callerAvatarUrl,
    calleeIds,
    type,
    status,
    isGroup,
    groupId,
    participants,
    createdAt,
    startedAt,
    endedAt,
  ];
}
