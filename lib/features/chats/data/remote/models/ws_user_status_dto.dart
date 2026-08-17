import 'package:equatable/equatable.dart';

/// DTO для WebSocket-события `user_status_changed`.
///
/// Сервер отправляет это событие когда пользователь подключается
/// (status = online) или отключается (status = offline).
/// При переходе в offline дополнительно передаётся [lastSeenMillis].
class WsUserStatusDto extends Equatable {
  /// Нормализованный userId (trim + toLowerCase) изменившего статус пользователя.
  final String userId;

  /// Текущий статус присутствия.
  final WsUserStatus status;

  /// Timestamp последнего появления в мс с эпохи Unix.
  /// Присутствует только при [status] == [WsUserStatus.offline].
  final int? lastSeenMillis;

  const WsUserStatusDto({required this.userId, required this.status, this.lastSeenMillis});

  factory WsUserStatusDto.fromMap(Map<String, dynamic> map) {
    return WsUserStatusDto(
      userId: (map['userId'] as String? ?? '').trim().toLowerCase(),
      status: map['status'] == 'online' ? WsUserStatus.online : WsUserStatus.offline,
      lastSeenMillis: (map['lastSeenMillis'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': 'user_status_changed',
      'userId': userId,
      'status': status.name,
      if (lastSeenMillis != null) 'lastSeenMillis': lastSeenMillis,
    };
  }

  @override
  List<Object?> get props => [userId, status, lastSeenMillis];

  @override
  String toString() =>
      'WsUserStatusDto(userId: $userId, status: $status, lastSeenMillis: $lastSeenMillis)';
}

/// Статус присутствия пользователя.
enum WsUserStatus {
  online,
  offline;

  static WsUserStatus fromString(String value) {
    return switch (value) {
      'online' => WsUserStatus.online,
      _ => WsUserStatus.offline,
    };
  }
}
