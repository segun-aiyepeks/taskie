import 'package:intl/intl.dart';

class DateHelper {
  DateHelper._();

  static String format(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final target = DateTime(date.year, date.month, date.day);

    String dateStr;
    if (target == today) {
      dateStr = 'Today';
    } else if (target == tomorrow) {
      dateStr = 'Tomorrow';
    } else if (target.year == now.year) {
      dateStr = DateFormat('d MMM').format(date);
    } else {
      dateStr = DateFormat('d MMM, yyyy').format(date);
    }

    if (date.hour != 0 || date.minute != 0) {
      final timeStr = DateFormat('h:mm a').format(date);
      return '$dateStr, $timeStr';
    }
    return dateStr;
  }

  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  static String fullDate(DateTime date) =>
      DateFormat('EEE, d MMM yyyy').format(date);

  static String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
