import 'package:equatable/equatable.dart';

/// Доменная сущность статуса набора текста в чате.
class TypingStatusEntity extends Equatable {
  /// Идентификатор чата, в котором происходит набор текста.
  final String chatId;

  /// Идентификатор пользователя, который печатает сообщение.
  final String userId;

  /// Флаг активности набора текста (`true` — печатает, `false` — перестал).
  final bool isTyping;

  const TypingStatusEntity({required this.chatId, required this.userId, required this.isTyping});

  @override
  List<Object?> get props => [chatId, userId, isTyping];

  @override
  String toString() => 'TypingStatusEntity(chatId: $chatId, userId: $userId, isTyping: $isTyping)';
}
