import 'package:flutter/material.dart';
import '../../data/models/timetable_entry.dart';

class AddEntryViewModel extends ChangeNotifier {
  final TextEditingController titleController;
  final TextEditingController noteController;
  final TimetableEntry? existingEntry;

  Set<int> _selectedDays;
  int    _startMinutes;
  int    _endMinutes;
  String _colorHex;
  bool   _isHighPriority;
  bool   _showNote;

  Set<int> get selectedDays    => _selectedDays;
  int      get startMinutes    => _startMinutes;
  int      get endMinutes      => _endMinutes;
  String   get colorHex        => _colorHex;
  bool     get isHighPriority  => _isHighPriority;
  bool     get showNote        => _showNote;
  bool     get isEditing       => existingEntry != null;

  bool get canSave =>
      titleController.text.trim().isNotEmpty &&
      _selectedDays.isNotEmpty &&
      _endMinutes > _startMinutes;

  static const List<String> palette = [
    '#4F67F8','#E84D2C','#2ABFA0',
    '#E09720','#8570C8','#3B9EDB',
  ];

  static const List<String> dayShort = [
    'Mon','Tue','Wed','Thu','Fri','Sat','Sun',
  ];

  AddEntryViewModel({required int initialDay, this.existingEntry})
      : titleController = TextEditingController(
            text: existingEntry?.title ?? ''),
        noteController  = TextEditingController(
            text: existingEntry?.note ?? ''),
        _selectedDays   = existingEntry != null
            ? Set<int>.from(existingEntry.daysOfWeek)
            : {initialDay},
        _startMinutes   = existingEntry?.startMinutes ?? 9 * 60,
        _endMinutes     = existingEntry?.endMinutes   ?? 10 * 60,
        _colorHex       = existingEntry?.colorHex     ?? palette[0],
        // New schedule entries remind by default; existing entries preserve
        // their saved reminder choice.
        _isHighPriority = existingEntry?.isHighPriority ?? true,
        _showNote       = existingEntry?.note?.isNotEmpty ?? false {
    titleController.addListener(notifyListeners);
  }

  // Toggle a day on/off — must always have at least one day selected
  void toggleDay(int day) {
    if (_selectedDays.contains(day)) {
      if (_selectedDays.length > 1) _selectedDays.remove(day);
    } else {
      _selectedDays.add(day);
    }
    notifyListeners();
  }

  bool isDaySelected(int day) => _selectedDays.contains(day);

  void setColor(String hex)         { _colorHex = hex;         notifyListeners(); }
  void setStartMinutes(int minutes) { _startMinutes = minutes; notifyListeners(); }
  void setEndMinutes(int minutes)   { _endMinutes = minutes;   notifyListeners(); }
  void toggleHighPriority()  { _isHighPriority = !_isHighPriority; notifyListeners(); }
  void toggleNote()          { _showNote = !_showNote;              notifyListeners(); }

  TimeOfDay minutesToTimeOfDay(int m) =>
      TimeOfDay(hour: m ~/ 60, minute: m % 60);

  int timeOfDayToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  String formatMinutes(int minutes) {
    final h      = minutes ~/ 60;
    final m      = minutes % 60;
    final period = h < 12 ? 'AM' : 'PM';
    final dh     = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$dh:${m.toString().padLeft(2, '0')} $period';
  }

  @override
  void dispose() {
    titleController.removeListener(notifyListeners);
    titleController.dispose();
    noteController.dispose();
    super.dispose();
  }
}
