import 'package:collab_tasks/features/calls/domain/models/call.dart';
import 'package:intl/intl.dart';

class CallHistoryFormatter {
  const CallHistoryFormatter._();

  static String date(DateTime value, String locale) => DateFormat.yMMMd(locale).format(value);

  static String time(DateTime value, String locale) => DateFormat.Hm(locale).format(value);

  static String? duration(Call call) {
    final value = call.duration;
    if (value == null) return null;
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}
