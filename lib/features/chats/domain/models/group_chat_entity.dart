import 'dart:convert';

import 'package:equatable/equatable.dart';

class GroupChatEntity extends Equatable {
  final String id;
  final List<String> participantUserIds;
  final List<String> participantEmails;
  final String title;
  final String description;
  final int updatedAtMillis;

  const GroupChatEntity({
    required this.id,
    required this.participantUserIds,
    required this.participantEmails,
    required this.title,
    required this.description,
    required this.updatedAtMillis,
  });

  GroupChatEntity copyWith({
    String? id,
    List<String>? participantUserIds,
    List<String>? participantEmails,
    String? title,
    String? description,
    int? updatedAtMillis,
  }) {
    return GroupChatEntity(
      id: id ?? this.id,
      participantUserIds: participantUserIds ?? this.participantUserIds,
      participantEmails: participantEmails ?? this.participantEmails,
      title: title ?? this.title,
      description: description ?? this.description,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participantUserIds': participantUserIds,
      'participantEmails': participantEmails,
      'title': title,
      'description': description,
      'updatedAtMillis': updatedAtMillis,
    };
  }

  factory GroupChatEntity.fromMap(Map<String, dynamic> map) {
    return GroupChatEntity(
      id: map['id'] as String,
      participantUserIds: List<String>.from(map['participantUserIds'] as Iterable),
      participantEmails: List<String>.from(map['participantEmails'] as Iterable),
      title: map['title'] as String,
      description: map['description'] as String,
      updatedAtMillis: (map['updatedAtMillis'] as num).toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory GroupChatEntity.fromJson(String source) =>
      GroupChatEntity.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
    id,
    participantUserIds,
    participantEmails,
    title,
    description,
    updatedAtMillis,
  ];
}
