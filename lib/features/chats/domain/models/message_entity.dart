import 'dart:convert';

import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final int createdAtMillis;

  const MessageEntity({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAtMillis,
  });

  MessageEntity copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? text,
    int? createdAtMillis,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'createdAtMillis': createdAtMillis,
    };
  }

  factory MessageEntity.fromMap(Map<String, dynamic> map) {
    return MessageEntity(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      senderName: map['senderName'] as String,
      text: map['text'] as String,
      createdAtMillis: (map['createdAtMillis'] as num).toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory MessageEntity.fromJson(String source) =>
      MessageEntity.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [id, senderId, senderName, text, createdAtMillis];
}
