import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taskie/data/repositories/task_repository.dart';

class StatsViewmodel extends ChangeNotifier {
  final TaskRepository _repository;

  Map<String, int> _stats = {
    'total': 0,
    'completed': 0,
    'pending': 0,
    'today': 0
  };

  StreamSubscription<Map<String, int>>? _sub;

  //Getters
  int get totalTasks => _stats['total'] ?? 0;
  int get completedTasks => _stats['completed'] ?? 0;
  int get pendingTasks => _stats['pending'] ?? 0;
  int get todayTasks => _stats['today'] ?? 0;
  int get highPriorityTasks   => _stats['high']   ?? 0;
  int get mediumPriorityTasks => _stats['medium'] ?? 0;
  int get lowPriorityTasks    => _stats['low']    ?? 0;

  //Returns a value between 0.0 and 1.0 - perfect for a progress ring
  double get completionRate {
    if(totalTasks == 0) return 0.0;
    return completedTasks/totalTasks;
  }

  StatsViewmodel(this._repository) {
    _sub = _repository.watchStats().listen((stats) {
      _stats = stats;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}