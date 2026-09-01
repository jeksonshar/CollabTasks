import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Компонент отображения даты в списке сообщений чата.
///
/// Размещается по центру окна чата, имеет закруглённые углы,
/// светло-серый фон и отображает дату:
/// - "1 сентября", "25 июля" (если год текущий)
/// - "23 мая 2025" (если год отличается от текущего).
class ChatDateSeparator extends StatelessWidget {
  final DateTime date;

  const ChatDateSeparator({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();

    final isCurrentYear = date.year == now.year;
    final formatPattern = isCurrentYear ? 'd MMMM' : 'd MMMM y';
    final formattedDate = DateFormat(formatPattern, locale).format(date);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isLight ? Colors.grey.shade200 : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          formattedDate,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isLight ? Colors.black54 : Colors.white70,
          ),
        ),
      ),
    );
  }
}
