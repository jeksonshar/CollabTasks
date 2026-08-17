import 'package:equatable/equatable.dart';

/// DTO для WebSocket-события `typing`.
///
/// Сервер рассылает это событие всем участникам прямого чата (кроме отправителя),
/// когда пользователь начинает или прекращает набор текста.
/// Событие **не** персистируется в базе данных.
class WsTypingDto extends Equatable {
  /// ID прямого чата, в котором происходит набор текста.
  final String chatId;

  /// Нормализованный userId (trim + toLowerCase) пользователя, набирающего текст.
  final String userId;

  /// `true` — пользователь начал печатать, `false` — остановился.
  final bool isTyping;

  const WsTypingDto({required this.chatId, required this.userId, required this.isTyping});

  factory WsTypingDto.fromMap(Map<String, dynamic> map) {
    return WsTypingDto(
      chatId: map['chatId'] as String? ?? '',
      userId: (map['userId'] as String? ?? '').trim().toLowerCase(),
      isTyping: map['isTyping'] as bool? ?? false,
    );
  }

  /// Клиент → Сервер: отправка события набора текста.
  Map<String, dynamic> toMap() {
    return {
      'type': 'typing',
      'chatId': chatId,
      'isTyping': isTyping,
      // userId — серверная сторона подставляет сама из аутентифицированного сокета
    };
  }

  @override
  List<Object?> get props => [chatId, userId, isTyping];

  @override
  String toString() => 'WsTypingDto(chatId: $chatId, userId: $userId, isTyping: $isTyping)';
}
