import 'package:collab_tasks/features/chats/domain/models/chat_entity.dart';

class ChatDto {
  final String id;
  final String type;
  final List<String> participantIds;
  final String lastMessage;
  final int updatedAtMillis;

  const ChatDto({
    required this.id,
    required this.type,
    required this.participantIds,
    required this.lastMessage,
    required this.updatedAtMillis,
  });

  factory ChatDto.fromFirestore(Map<String, dynamic> json, String id) {
    return ChatDto(
      id: id,
      type: json['type'] as String? ?? 'direct',
      participantIds: List<String>.from(json['participantIds'] as Iterable? ?? const []),
      lastMessage: json['lastMessage'] as String? ?? '',
      updatedAtMillis: (json['updatedAtMillis'] as num? ?? 0).toInt(),
    );
  }

  ChatEntity toDomain() {
    return ChatEntity(
      id: id,
      type: ChatType.values.byName(type),
      participantIds: participantIds,
      lastMessage: lastMessage,
      updatedAtMillis: updatedAtMillis,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'updatedAtMillis': updatedAtMillis,
    };
  }
}
