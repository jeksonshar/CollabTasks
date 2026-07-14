import 'package:collab_tasks/features/chats/domain/models/message_entity.dart';

class MessageDto {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final int createdAtMillis;

  const MessageDto({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAtMillis,
  });

  factory MessageDto.fromFirestore(Map<String, dynamic> json, String id) {
    return MessageDto(
      id: id,
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAtMillis: (json['createdAtMillis'] as num? ?? 0).toInt(),
    );
  }

  MessageEntity toDomain() {
    return MessageEntity(
      id: id,
      senderId: senderId,
      senderName: senderName,
      text: text,
      createdAtMillis: createdAtMillis,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'createdAtMillis': createdAtMillis,
    };
  }
}
