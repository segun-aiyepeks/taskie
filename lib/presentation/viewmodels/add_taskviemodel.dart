import 'package:flutter/material.dart';
import '../../core/constants/app_enums.dart';
import '../../data/models/task.dart';

class AddTaskViewModel extends ChangeNotifier {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final Task? existingTask; // null = new task, non-null = editing

  Priority  _priority;
  int?      _categoryId;
  DateTime? _dueDate;
  bool      _showDescription;

  Priority  get priority        => _priority;
  int?      get categoryId      => _categoryId;
  DateTime? get dueDate         => _dueDate;
  bool      get showDescription => _showDescription;
  bool      get isEditing       => existingTask != null;
  bool      get canSave         => titleController.text.trim().isNotEmpty;

  AddTaskViewModel({this.existingTask})
      : titleController = TextEditingController(
          text: existingTask?.title ?? '',
        ),
        descriptionController = TextEditingController(
          text: existingTask?.description ?? '',
        ),
        _priority   = existingTask?.priority ?? Priority.medium,
        _categoryId = (existingTask == null || existingTask.categoryId == 0)
            ? null
            : existingTask.categoryId,
        _dueDate         = existingTask?.dueDate,
        _showDescription =
            existingTask?.description?.isNotEmpty ?? false {
    titleController.addListener(notifyListeners);
  }

  void setPriority(Priority p)    { _priority = p;    notifyListeners(); }
  void setCategoryId(int? id)     { _categoryId = id; notifyListeners(); }
  void setDueDate(DateTime? date) { _dueDate = date;  notifyListeners(); }
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