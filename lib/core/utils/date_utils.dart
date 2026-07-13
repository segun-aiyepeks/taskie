import 'package:intl/intl.dart';

class DateHelper{
  DateHelper._();

  static String format(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return 'Today';
    if (target == tomorrow) return 'Tomorrow';
    if (target.year == now.year) return DateFormat('d MMM').format(date);
    return DateFormat('d MMM, yyyy').format(date);
  }

  static String greeting() {
    final h = DateTime.now().hour;
    if(h < 12) return 'Good morning';
    if(h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}