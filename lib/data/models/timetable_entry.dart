import 'package:isar/isar.dart';

part 'timetable_entry.g.dart';

@collection
class TimetableEntry {
  Id id = Isar.autoIncrement;

  late String title;
  String?  note;

  @Index()
  late int dayOfTheWeek;
  late int startMinutes;
  late int endMinutes;
  late String colorHex;
  DateTime createdAt = DateTime.now();

  // Computed Helpers
  int get durationMinutes => endMinutes - startMinutes;

  String get durationLabel {
    final h = durationMinutes ~/60;
    final m = durationMinutes % 60;
    if(h == 0) return '${m}min';
    if(m == 0) return '${h}h';

    return '${h}h ${m}min';
  }

  String get startLabel => _minutesToLabel(startMinutes);
  String get endLabel => _minutesToLabel(endMinutes);
  String get timeRange => '$startLabel - $endLabel';

  static String _minutesToLabel(int minutes){
    final h = minutes ~/60;
    final m = minutes % 60;
    final period = h < 12 ? 'AM' : 'PM';
    final displayH = h==0 ? 12 : (h > 12 ? h - 12 : h);
    
    return '$displayH: ${m.toString().padLeft(2, '0')} $period';
  }
}