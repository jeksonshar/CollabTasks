/// Результат поиска/создания прямого чата с участником группы.
class DirectChatResult {
  const DirectChatResult({required this.chatId, required this.opponentName});

  final String chatId;
  final String opponentName;
}
