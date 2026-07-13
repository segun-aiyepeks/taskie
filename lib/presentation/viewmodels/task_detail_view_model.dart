import 'package:flutter/material.dart';

class TaskDetailViewModel extends ChangeNotifier {
  final subtaskController = TextEditingController();
  bool _showInput = false;

  bool get showInput => _showInput;
  bool get canAdd => subtaskController.text.trim().isNotEmpty;

  TaskDetailViewModel() {
    subtaskController.addListener(notifyListeners);
  }

  void openInput() {
    _showInput = true;
    notifyListeners();
  }

  void closeInput() {
    _showInput = false;
    subtaskController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    subtaskController.removeListener(notifyListeners);
    subtaskController.dispose();
    super.dispose();
  }
}