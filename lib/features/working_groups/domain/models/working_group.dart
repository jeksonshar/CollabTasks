import 'package:equatable/equatable.dart';

class WorkingGroup extends Equatable {
  const WorkingGroup({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final int updatedAt;

  WorkingGroup copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    int? updatedAt,
  }) {
    return WorkingGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap({List<String> participantUserIds = const []}) {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAtMillis': updatedAt,
      'participantUserIds': participantUserIds,
    };
  }

  factory WorkingGroup.fromMap(Map<String, dynamic> map) {
    return WorkingGroup(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      createdAt: _dateTimeFromMillis(map['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: (map['updatedAtMillis'] as num?)?.toInt() ?? 0,
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
  List<Object?> get props => [id, title, description, createdAt, updatedAt];
}
