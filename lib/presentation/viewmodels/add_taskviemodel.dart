import 'package:flutter/material.dart';
import '../../core/constants/app_enums.dart';
import '../../data/models/task.dart';

class AddTaskViewModel extends ChangeNotifier {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final Task? existingTask; // null = new task, non-null = editing

  Priority _priority;
  int? _categoryId;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _showDescription;

  Priority get priority => _priority;
  int? get categoryId => _categoryId;
  DateTime? get dueDate => _dueDate;
  TimeOfDay? get dueTime => _dueTime;
  bool get showDescription => _showDescription;
  bool get isEditing => existingTask != null;
  bool get canSave => titleController.text.trim().isNotEmpty;

  DateTime? get fullDueDate {
    if (_dueDate == null) return null;
    if (_dueTime != null) {
      return DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _dueTime!.hour,
        _dueTime!.minute,
      );
    }
    final now = DateTime.now();
    final isToday =
        _dueDate!.year == now.year &&
        _dueDate!.month == now.month &&
        _dueDate!.day == now.day;
    if (isToday) {
      if (now.hour < 18) {
        return DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day, 18, 0);
      } else {
        return DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day, 23, 59);
      }
    }
    return DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day, 9, 0);
  }

  AddTaskViewModel({this.existingTask, DateTime? defaultDueDate})
    : titleController = TextEditingController(text: existingTask?.title ?? ''),
      descriptionController = TextEditingController(
        text: existingTask?.description ?? '',
      ),
      _priority = existingTask?.priority ?? Priority.medium,
      _categoryId = (existingTask == null || existingTask.categoryId == 0)
          ? null
          : existingTask.categoryId,
      _dueDate = existingTask?.dueDate ?? defaultDueDate,
      _dueTime = existingTask?.dueDate != null
          ? TimeOfDay.fromDateTime(existingTask!.dueDate!.toLocal())
          : null,
      _showDescription = existingTask?.description?.isNotEmpty ?? false {
    titleController.addListener(notifyListeners);
  }

  void setPriority(Priority p) {
    _priority = p;
    notifyListeners();
  }

  void setCategoryId(int? id) {
    _categoryId = id;
    notifyListeners();
  }

  void setDueDate(DateTime? date) {
    _dueDate = date;
    if (date == null) _dueTime = null;
    notifyListeners();
  }

  void setDueTime(TimeOfDay? time) {
    if (time != null && _dueDate == null) {
      final now = DateTime.now();
      _dueDate = DateTime(now.year, now.month, now.day);
    }
    _dueTime = time;
    notifyListeners();
  }

  void toggleDescription() {
    _showDescription = !_showDescription;
    notifyListeners();
  }

  @override
  void dispose() {
    titleController.removeListener(notifyListeners);
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
