import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AddEntryViewModel extends ChangeNotifier {
  final titleController = TextEditingController();
  final noteController = TextEditingController();

  int _selectedDay;
  int _startMinutes;
  int _endMinutes;
  String _colorHex;
  bool _showNote = false;

  int get selectedDay => _selectedDay;
  int get startMinutes => _startMinutes;
  int get endMinutes => _endMinutes;
  String get colorHex => _colorHex;
  bool get showNote => _showNote;

  bool get canSave => titleController.text.trim().isNotEmpty && _endMinutes > startMinutes;

  static const List<String> palletes = ['#4F67F8', '#E84D2C', '#2ABFA0',
    '#E09720', '#8570C8', '#3B9EDB'
  ];
  
  static const List<String> dayShort = [
    'Mon', 'Tue', 'Wed', 'Thurs', 'Fri', 'Sat', 'Sun'
  ];

  AddEntryViewModel({required int initialDay})
    : _selectedDay = initialDay,
      _startMinutes = 9 * 60,
      _endMinutes = 10 * 60,
      _colorHex = palletes[0] {titleController.addListener(notifyListeners);
    }

    void setDay(int day) {_selectedDay = day; notifyListeners();}
    void setColor(String hex) {_colorHex = hex; notifyListeners();}
    void setStartMinutes(int minutes) {_startMinutes = minutes; notifyListeners();}
    void setEndMinutes(int minutes) {_endMinutes = minutes; notifyListeners();}
    void toggleNote() {_showNote = !_showNote; notifyListeners();}

    TimeOfDay minutesToTimeOfDay(int minutes) => TimeOfDay(hour: minutes ~/60, minute: minutes % 60);
    
    int timeOfDayToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

    String formatMinutes(int minutes) {
      final h = minutes ~/60;
      final m = minutes % 60;
      final period = h < 12 ? 'AM' : 'PM';
      final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);

      return '$dh: ${m.toString().padLeft(2, "0")} $period';
    }

    @override
  void dispose() {
    titleController.removeListener(notifyListeners);
    titleController.dispose();
    noteController.dispose();
    super.dispose();
  }

}