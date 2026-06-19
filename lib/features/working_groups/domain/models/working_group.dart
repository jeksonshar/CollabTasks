import 'package:equatable/equatable.dart';

class WorkingGroup extends Equatable {
  const WorkingGroup({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
  });

  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final int updatedAt;
  final String? avatarUrl;

  WorkingGroup copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    int? updatedAt,
    String? avatarUrl,
  }) {
    return WorkingGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toMap({
    List<String> participantUserIds = const [],
    List<String> participantEmails = const [],
  }) {
    return {
      'id': id,
      'title': title,
      'description': description,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAtMillis': updatedAt,
      'participantUserIds': participantUserIds,
      'participantEmails': participantEmails,
    };
  }

  factory WorkingGroup.fromMap(Map<String, dynamic> map) {
    return WorkingGroup(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      createdAt: _dateTimeFromMillis(map['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: (map['updatedAtMillis'] as num?)?.toInt() ?? 0,
      avatarUrl: map['avatarUrl'] as String?,
    );
  }

  static DateTime? _dateTimeFromMillis(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props => [id, title, description, createdAt, updatedAt, avatarUrl];
}
