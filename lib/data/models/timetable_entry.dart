import 'package:isar/isar.dart';

part 'timetable_entry.g.dart';

@collection
class TimetableEntry {
  Id id = Isar.autoIncrement;

  late String title;
  String? note;

  // Changed from single int to List<int>
  // e.g. [1, 3, 5] = Monday, Wednesday, Friday
  late List<int> daysOfWeek;

  late int startMinutes;
  late int endMinutes;
  late String colorHex;
  bool isHighPriority = false; // used in Fix 5
  DateTime createdAt = DateTime.now();

  // ── Computed ────────────────────────────────────────────
  String get startLabel    => _minutesToLabel(startMinutes);
  String get endLabel      => _minutesToLabel(endMinutes);
  String get timeRange     => '$startLabel – $endLabel';
  int    get durationMinutes => endMinutes - startMinutes;

  String get durationLabel {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  // Shows which days the entry repeats on — e.g. "Mon, Wed, Fri"
  String get daysLabel {
    if (daysOfWeek.isEmpty) return '';
    if (daysOfWeek.length == 7) return 'Every day';
    const names = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final sorted = List<int>.from(daysOfWeek)..sort();
    return sorted.map((d) => names[d - 1]).join(', ');
  }

  static String _minutesToLabel(int minutes) {
    final h      = minutes ~/ 60;
    final m      = minutes % 60;
    final period = h < 12 ? 'AM' : 'PM';
    final dh     = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$dh:${m.toString().padLeft(2, '0')} $period';
  }
}