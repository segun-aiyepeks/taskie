import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taskie/core/constants/app_enums.dart';
import 'package:taskie/core/services/notification_service.dart';
import 'package:taskie/data/models/subtasks.dart';
import 'package:taskie/data/models/task.dart';
import 'package:taskie/data/repositories/task_repository.dart';
import 'package:uuid/uuid.dart';

class TaskViewModel extends ChangeNotifier {
  final TaskRepository _repository;

  //Private State
  List<Task> _allTasks = [];
  bool _isLoading = false;
  String? _error;

  //Filter State
  TaskFilter _activeFilter = TaskFilter.all;
  int? _filterCategoryId;
  String _searchQuery = '';

  //Stream Subscription
  StreamSubscription<List<Task>>? _tasksSub;

  //Constructor
  TaskViewModel(this._repository) {
    _init();
  }

  void _init() {
    _isLoading = true;

    _tasksSub = _repository.watchAllTasks().listen(
      (tasks) {
        _allTasks = tasks;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  //Public Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  TaskFilter get activeFilter => _activeFilter;
  int? get filterCategoryId => _filterCategoryId;
  String get searchQuery => _searchQuery;
  List<Task> get allTask => _allTasks;

  //Quick Counts
  int get totalCount => _allTasks.length;
  int get completedCount => _allTasks.where((t) => t.isCompleted).length;
  int get pendingCount => _allTasks.where((t) => t.isPending).length;
  int get todayCount => _allTasks.where((t) => t.isOverdue).length;

  //Filtered Tasks
  List<Task> get filteredTasks {
    //Step 1: apply the tab filter
    var tasks = switch (_activeFilter) {
      TaskFilter.all  => List<Task>.from(_allTasks),
      TaskFilter.today => _allTasks.where((t) => t.isDueToday).toList(),
      TaskFilter.pending => _allTasks.where((t) => t.isPending).toList(),
      TaskFilter.completed => _allTasks.where((t) => t.isCompleted).toList()
    };

    //Step 2: apply category filter
    if(_filterCategoryId != null) {
      tasks = tasks.where((t) => t.categoryId == _filterCategoryId).toList();
    }

    //Step 3: apply search query
    if(searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      tasks = tasks.where((t) => t.title.toLowerCase().contains(q) || (t.description?.toLowerCase().contains(q) ?? false)).toList();
    }
    return tasks;
  }

  //Filter Controls
  void setFilter(TaskFilter filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  void setFilterCategory(int? categoryId) {
    _filterCategoryId = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _activeFilter = TaskFilter.all;
    _filterCategoryId = null;
    _searchQuery = '';
    notifyListeners();
  }

  //CRUD Operations
  Future<void> addTask({
    required String title,
    String? description,
    Priority priority = Priority.medium,
    int categoryId = 0,
    DateTime? dueDate,
    List<Subtasks> subtasks = const [],
  }) async {
    try {
      final task = Task()
      ..title = title
      ..description = description
      ..priority = priority
      ..status = TaskStatus.pending
      ..createdAt = DateTime.now()
      ..categoryId = categoryId
      ..dueDate = dueDate
      ..subtasks = subtasks;

      final id = await _repository.saveTask(task);

      if(dueDate != null){
        await NotificationService.instance.scheduleTaskReminder(
          taskId: id, 
          taskTitle: title, 
          dueDate: dueDate
        );
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTask(Task task) async {
    try{
      await _repository.saveTask(task);
      await NotificationService.instance.cancelTaskNotification(task.id);

      if(task.dueDate != null && task.isPending) {
        await NotificationService.instance.scheduleTaskReminder(taskId: task.id, taskTitle: task.title, dueDate: task.dueDate!);
      }
    } catch(e){
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTask(int id) async {
    try{
      await NotificationService.instance.cancelTaskNotification(id);
      await _repository.deleteTask(id);
    } catch(e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleTaskCompletion(int id) async {
    try {
      await _repository.toggleTaskCompletion(id);
      final task = await _repository.getTaskById(id);

      if(task != null) {
        if(task.isCompleted){
          //Task done - cancel reminder
          await NotificationService.instance.cancelTaskNotification(id);
        }else if(task.dueDate != null){
          await NotificationService.instance.scheduleTaskReminder(taskId: id, taskTitle: task.title, dueDate: task.dueDate!);
        }
      }
    } catch(e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError(){
    _error = null;
    notifyListeners();
  }
  
  //Lookup
  Task? getTaskbyId(int id) {
    try {
      return _allTasks.firstWhere((t) => t.id == t.id);
    } catch(_){
      return null;
    }
  }

  //Subtasks Operation
  Future<void> addSubtasks(int taskId, String title) async {
    try {
      final task = await _repository.getTaskById(taskId);
      if(task == null) return;

      final newSubtask = Subtasks()
      ..subtaskId = const Uuid().v4()
      ..title = title.trim()
      ..isCompleted = false
      ..createdAt = DateTime.now();

      task.subtasks = [...task.subtasks, newSubtask];
      await _repository.saveTask(task);
    } catch(e){
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleSubtask(int taskId, String subtasksId) async {
    try {
      final task = await _repository.getTaskById(taskId);
      if(task == null) return;

      task.subtasks = task.subtasks.map((s) {
        if(s.subtaskId != subtasksId) return s;
        return Subtasks()
        ..subtaskId = s.subtaskId
        ..title = s.title
        ..isCompleted = s.isCompleted
        ..createdAt = s.createdAt;
      }).toList();

      await _repository.saveTask(task);
    } catch(e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteSubTask(int taskId, String subtaskId) async {
    try {
      final task = await _repository.getTaskById(taskId);
      if(task == null) return;

      task.subtasks = task.subtasks.where((s) => s.subtaskId != subtaskId).toList();
      await _repository.saveTask(task);

    } catch(e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  //Dispose
  @override
  void dispose() {
    _tasksSub?.cancel();
    super.dispose();
  }
}