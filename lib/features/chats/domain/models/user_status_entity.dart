import 'package:equatable/equatable.dart';

/// Статус присутствия пользователя (онлайн / офлайн).
enum UserStatus {
  online,
  offline;

  bool get isOnline => this == UserStatus.online;

  bool get isOffline => this == UserStatus.offline;
}

/// Доменная сущность статуса пользователя в реальном времени.
class UserStatusEntity extends Equatable {
  /// Нормализованный идентификатор пользователя (UID или Email).
  final String userId;

  /// Статус присутствия пользователя.
  final UserStatus status;

  /// Timestamp последнего появления в миллисекундах (UTC/Unix time).
  /// Заполняется только при переходе в офлайн.
  final int? lastSeenMillis;

  const UserStatusEntity({required this.userId, required this.status, this.lastSeenMillis});

  bool get isOnline => status.isOnline;

  bool get isOffline => status.isOffline;

  DateTime? get lastSeen =>
      lastSeenMillis != null ? DateTime.fromMillisecondsSinceEpoch(lastSeenMillis!) : null;

  @override
  List<Object?> get props => [userId, status, lastSeenMillis];

  @override
  String toString() =>
      'UserStatusEntity(userId: $userId, status: $status, lastSeenMillis: $lastSeenMillis)';
}
