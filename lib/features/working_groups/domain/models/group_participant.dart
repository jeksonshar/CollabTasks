import 'package:equatable/equatable.dart';

class GroupParticipant extends Equatable {
  const GroupParticipant({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.updatedAt,
  });

  final String id;
  final String groupId;
  final String userId;
  final String name;
  final String? avatarUrl;
  final int updatedAt;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((part) => part.substring(0, 1).toUpperCase()).join();
  }

  GroupParticipant copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? name,
    String? avatarUrl,
    int? updatedAt,
  }) {
    return GroupParticipant(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'userId': userId,
      'name': name,
      'avatarUrl': avatarUrl,
      'updatedAtMillis': updatedAt,
    };
  }

  factory GroupParticipant.fromMap(Map<String, dynamic> map) {
    return GroupParticipant(
      id: map['id'] as String,
      groupId: map['groupId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
      updatedAt: (map['updatedAtMillis'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, groupId, userId, name, avatarUrl, updatedAt];
}
