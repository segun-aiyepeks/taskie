import '../models/timetable_entry.dart';

abstract class TimetableRepository {
  Future<int>              saveEntry(TimetableEntry entry);
  Future<void>             deleteEntry(int id);
  Future<TimetableEntry?>  getEntryById(int id);
  Stream<List<TimetableEntry>> watchEntriesForDay(int dayOfWeek);
  Stream<List<TimetableEntry>> watchAllEntries();
}