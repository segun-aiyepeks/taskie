import 'package:taskie/data/models/timetable_entry.dart';

abstract class TimetableRepository {
  Future<int> saveEntry(TimetableEntry entry);
  Future<void> deleteEntry(int Id);

  Stream<List<TimetableEntry>> watchEntriesForDay(int dayOfTheWeek);
  Stream<List<TimetableEntry>> watchAllEntries();
}