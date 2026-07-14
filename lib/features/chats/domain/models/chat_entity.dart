import 'dart:convert';

import 'package:equatable/equatable.dart';

enum ChatType { direct, group }

class ChatEntity extends Equatable {
  final String id;
  final ChatType type;
  final List<String> participantIds;
  final String lastMessage;
  final int updatedAtMillis;

  const ChatEntity({
    required this.id,
    required this.type,
    required this.participantIds,
    required this.lastMessage,
    required this.updatedAtMillis,
  });

  ChatEntity copyWith({
    String? id,
    ChatType? type,
    List<String>? participantIds,
    String? lastMessage,
    int? updatedAtMillis,
  }) {
    return ChatEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'updatedAtMillis': updatedAtMillis,
    };
  }

  factory ChatEntity.fromMap(Map<String, dynamic> map) {
    return ChatEntity(
      id: map['id'] as String,
      type: ChatType.values.byName(map['type'] as String),
      participantIds: List<String>.from(map['participantIds'] as Iterable),
      lastMessage: map['lastMessage'] as String,
      updatedAtMillis: (map['updatedAtMillis'] as num).toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatEntity.fromJson(String source) =>
      ChatEntity.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [id, type, participantIds, lastMessage, updatedAtMillis];
}
