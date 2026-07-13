import 'package:isar/isar.dart';
import '../../data/models/timetable_entry.dart';
import '../../data/repositories/timetable_repository.dart';

class IsarTimetableRepository implements TimetableRepository {
  final Isar _isar;
  IsarTimetableRepository(this._isar);

  @override
  Future<int> saveEntry(TimetableEntry entry) =>
      _isar.writeTxn(() => _isar.timetableEntrys.put(entry)); // ← put not push

  @override
  Future<void> deleteEntry(int id) async {
    // ← completely rewritten: writeTxn + delete
    await _isar.writeTxn(() => _isar.timetableEntrys.delete(id));
  }

  @override
  Stream<List<TimetableEntry>> watchEntriesForDay(int dayOfWeek) {
    // ← kept on one line, no line break inside the method call
    return _isar.timetableEntrys
        .filter()
        .dayOfTheWeekEqualTo(dayOfWeek)
        .sortByStartMinutes()
        .watch(fireImmediately: true);
  }

  @override
  Stream<List<TimetableEntry>> watchAllEntries() {
    return _isar.timetableEntrys
        .where()
        .sortByDayOfTheWeek()           // ← capital O and W
        .thenByStartMinutes()
        .watch(fireImmediately: true);
  }
}