import 'package:isar/isar.dart';
import '../models/timetable_entry.dart';
import 'timetable_repository.dart';

class IsarTimetableRepository implements TimetableRepository {
  final Isar _isar;
  IsarTimetableRepository(this._isar);

  @override
  Future<int> saveEntry(TimetableEntry entry) =>
      _isar.writeTxn(() => _isar.timetableEntrys.put(entry));

  @override
  Future<void> deleteEntry(int id) =>
      _isar.writeTxn(() => _isar.timetableEntrys.delete(id));

  @override
  Future<TimetableEntry?> getEntryById(int id) =>
      _isar.timetableEntrys.get(id);

  @override
  Stream<List<TimetableEntry>> watchEntriesForDay(int dayOfWeek) {
    // Isar supports querying inside List fields with ElementEqualTo
    return _isar.timetableEntrys
        .filter()
        .daysOfWeekElementEqualTo(dayOfWeek)
        .sortByStartMinutes()
        .watch(fireImmediately: true);
  }

  @override
  Stream<List<TimetableEntry>> watchAllEntries() {
    return _isar.timetableEntrys
        .where()
        .sortByStartMinutes()
        .watch(fireImmediately: true);
  }
}