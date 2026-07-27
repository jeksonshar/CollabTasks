import 'package:collab_tasks/features/chats/domain/models/group_chat_entity.dart';

class GroupChatDto {
  final String id;
  final List<String> participantUserIds;
  final List<String> participantEmails;
  final String title;
  final String description;
  final int updatedAtMillis;

  const GroupChatDto({
    required this.id,
    required this.participantUserIds,
    required this.participantEmails,
    required this.title,
    required this.description,
    required this.updatedAtMillis,
  });

  factory GroupChatDto.fromFirestore(Map<String, dynamic> json, String id) {
    return GroupChatDto(
      id: id,
      participantUserIds: List<String>.from(json['participantUserIds'] as Iterable? ?? const []),
      participantEmails: List<String>.from(json['participantEmails'] as Iterable? ?? const []),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      updatedAtMillis: (json['updatedAtMillis'] as num? ?? 0).toInt(),
    );
  }

  GroupChatEntity toDomain() {
    return GroupChatEntity(
      id: id,
      participantUserIds: participantUserIds,
      participantEmails: participantEmails,
      title: title,
      description: description,
      updatedAtMillis: updatedAtMillis,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participantUserIds': participantUserIds,
      'participantEmails': participantEmails,
      'title': title,
      'description': description,
      'updatedAtMillis': updatedAtMillis,
    };
  }
}
