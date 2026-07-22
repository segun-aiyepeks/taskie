import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:taskie/core/services/notification_service.dart';
import 'package:taskie/data/models/timetable_entry.dart';
import 'package:taskie/data/repositories/timetable_repository.dart';

class TimetableViewModel extends ChangeNotifier {
  final TimetableRepository _repository;

  //Default to Today's weekday
  int _selectedDay = DateTime.now().weekday;
  List<TimetableEntry> _entries = [];
  bool _isLoading = true;
  StreamSubscription<List<TimetableEntry>>? _sub;

  int get selectedDay => _selectedDay;
  bool get isLoading => _isLoading;
  List<TimetableEntry> get entries => _entries;

  int get entryCount => _entries.length;

  static const List<String> dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday' 
  ];

  static const List<String> dayShort = [
    'Mon', 'Tue', 'Wed', 'Thurs', 'Fri', 'Sat', 'Sun'
  ];

  String get selectedDayName => dayNames[_selectedDay - 1];

  TimetableViewModel(this._repository) {
    _subscribeToDay(_selectedDay);
  }

  void selectDay(int day) {
    if(_selectedDay == day) return;
    _selectedDay = day;
    _sub?.cancel();
    _subscribeToDay(day);
    notifyListeners();
  }

  void _subscribeToDay(int day) {
    _isLoading = true;
    _sub = _repository.watchEntriesForDay(day).listen((entries) {
      _entries = entries;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addEntry(TimetableEntry entry) async {
  final id = await _repository.saveEntry(entry);

  // Schedule weekly notification for each selected day
  // if the entry is marked high priority
  if (entry.isHighPriority) {
    for (final day in entry.daysOfWeek) {
      await NotificationService.instance.scheduleWeeklyTimetableReminder(
        entryId:      id,
        dayOfWeek:    day,
        title:        entry.title,
        startMinutes: entry.startMinutes,
      );
    }
  }
}

  Future<void> deleteEntry(int id) async {
  // Always cancel all notifications for this entry before deleting
  await NotificationService.instance.cancelTimetableNotification(id);
  await _repository.deleteEntry(id);
}

  Future<void> updateEntry(TimetableEntry entry) async {
  await _repository.saveEntry(entry);
  // High priority notification update
  await NotificationService.instance.cancelTimetableNotification(entry.id);
  if (entry.isHighPriority) {
    for (final day in entry.daysOfWeek) {
      await NotificationService.instance.scheduleWeeklyTimetableReminder(
        entryId:      entry.id,
        dayOfWeek:    day,
        title:        entry.title,
        startMinutes: entry.startMinutes,
      );
    }
  }
}

  @override
  void dispose() {
   _sub?.cancel();
    super.dispose();
  }
}