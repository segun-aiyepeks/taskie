import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taskie/core/constants/app_enums.dart';
import 'package:taskie/core/services/notification_service.dart';
import 'package:taskie/data/models/subtasks.dart';
import 'package:taskie/data/models/task.dart';
import 'package:taskie/data/repositories/task_repository.dart';
import 'package:uuid/uuid.dart';

class TaskViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final TaskRepository _repository;
  final DateTime Function() _clock;
  late DateTime _now;
  Timer? _calendarTimer;

  //Private State
  List<Task> _allTasks = [];
  bool _isLoading = false;
  String? _error;

  //Filter & Sort State
  TaskFilter _activeFilter = TaskFilter.today;
  int? _filterCategoryId;
  String _searchQuery = '';
  TaskSortOption _sortOption = TaskSortOption.createdAt;

  //Stream Subscription
  StreamSubscription<List<Task>>? _tasksSub;

  //Constructor
  TaskViewModel(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _now = _clock().toLocal();
    WidgetsBinding.instance.addObserver(this);
    _init();
    _scheduleCalendarRefresh();
  }

  void _init() {
    _isLoading = true;

    _tasksSub = _repository.watchAllTasks().listen(
      (tasks) {
        _allTasks = tasks;
        _isLoading = false;
        refreshTime();
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
  TaskSortOption get sortOption => _sortOption;
  List<Task> get allTask => _allTasks;
  DateTime get now => _now;
  List<Task> get currentTasks =>
      _allTasks.where((task) => !task.isPreviousAt(_now)).toList();
  List<Task> get todayTasks =>
      _allTasks.where((task) => task.isScheduledFor(_now)).toList();

  Map<DateTime, List<Task>> get archivedTasksByDate {
    final previous = _allTasks.where((task) => task.isPreviousAt(_now)).toList()
      ..sort((a, b) {
        final byDay = b.scheduledDay.compareTo(a.scheduledDay);
        if (byDay != 0) return byDay;
        return (a.dueDate ?? a.createdAt).compareTo(b.dueDate ?? b.createdAt);
      });
    final groups = <DateTime, List<Task>>{};
    for (final task in previous) {
      (groups[task.scheduledDay] ??= []).add(task);
    }
    return groups;
  }

  int get archivedCount =>
      _allTasks.where((task) => task.isPreviousAt(_now)).length;

  //Quick Counts
  int get totalCount => _allTasks.length;
  int get completedCount => _allTasks.where((t) => t.isCompleted).length;
  int get pendingCount => _allTasks.where((t) => t.isPending).length;
  int get todayCount => todayTasks.length;
  int get todayCompletedCount => todayTasks.where((t) => t.isCompleted).length;

  /// Refresh on resume as well as at the next deadline or local midnight.
  void refreshTime() {
    final currentTime = _clock().toLocal();
    if (!DateUtils.isSameDay(_now, currentTime)) {
      _activeFilter = TaskFilter.today;
    }
    _now = currentTime;
    _scheduleCalendarRefresh();
    notifyListeners();
  }

  void _scheduleCalendarRefresh() {
    _calendarTimer?.cancel();
    var nextChange = DateTime(_now.year, _now.month, _now.day + 1);
    for (final task in _allTasks) {
      final due = task.dueDate;
      if (task.isPending &&
          due != null &&
          due.isAfter(_now) &&
          due.isBefore(nextChange)) {
        nextChange = due;
      }
    }
    _calendarTimer = Timer(nextChange.difference(_now), refreshTime);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshTime();
  }

  //Filtered Tasks
  List<Task> get filteredTasks {
    final activeTasks = currentTasks;
    //Step 1: apply the tab filter
    var tasks = switch (_activeFilter) {
      TaskFilter.all => activeTasks,
      TaskFilter.today =>
        activeTasks.where((t) => t.isScheduledFor(_now)).toList(),
      TaskFilter.pending => activeTasks.where((t) => t.isPending).toList(),
      TaskFilter.completed => activeTasks.where((t) => t.isCompleted).toList(),
      TaskFilter.expired =>
        activeTasks.where((t) => t.isExpiredAt(_now)).toList(),
    };

    //Step 2: apply category filter
    if (_filterCategoryId != null) {
      tasks = tasks.where((t) => t.categoryId == _filterCategoryId).toList();
    }

    //Step 3: apply search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      tasks = tasks
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                (t.description?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    //Step 4: apply sorting
    switch (_sortOption) {
      case TaskSortOption.dueDate:
        tasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
      case TaskSortOption.priority:
        tasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      case TaskSortOption.title:
        tasks.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case TaskSortOption.createdAt:
        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

  void setSortOption(TaskSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void clearFilters() {
    _activeFilter = TaskFilter.today;
    _filterCategoryId = null;
    _searchQuery = '';
    _sortOption = TaskSortOption.createdAt;
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

      if (dueDate != null) {
        await NotificationService.instance.scheduleTaskReminder(
          taskId: id,
          taskTitle: title,
          dueDate: dueDate,
        );
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _repository.saveTask(task);
      await NotificationService.instance.cancelTaskNotification(task.id);

      if (task.dueDate != null && task.isPending) {
        await NotificationService.instance.scheduleTaskReminder(
          taskId: task.id,
          taskTitle: task.title,
          dueDate: task.dueDate!,
        );
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await NotificationService.instance.cancelTaskNotification(id);
      await _repository.deleteTask(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleTaskCompletion(int id) async {
    try {
      await _repository.toggleTaskCompletion(id);
      final task = await _repository.getTaskById(id);

      if (task != null) {
        if (task.isCompleted) {
          //Task done - cancel reminder
          await NotificationService.instance.cancelTaskNotification(id);
        } else if (task.dueDate != null) {
          await NotificationService.instance.scheduleTaskReminder(
            taskId: id,
            taskTitle: task.title,
            dueDate: task.dueDate!,
          );
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  //Lookup
  Task? getTaskbyId(int id) {
    try {
      return _allTasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  //Subtasks Operation
  Future<void> addSubtasks(int taskId, String title) async {
    try {
      final task = await _repository.getTaskById(taskId);
      if (task == null) return;

      final newSubtask = Subtasks()
        ..subtaskId = const Uuid().v4()
        ..title = title.trim()
        ..isCompleted = false
        ..createdAt = DateTime.now();

      task.subtasks = [...task.subtasks, newSubtask];
      await _repository.saveTask(task);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleSubtask(int taskId, String subtasksId) async {
    try {
      final task = await _repository.getTaskById(taskId);
      if (task == null) return;

      task.subtasks = task.subtasks.map((s) {
        if (s.subtaskId != subtasksId) return s;
        return Subtasks()
          ..subtaskId = s.subtaskId
          ..title = s.title
          ..isCompleted = !s.isCompleted
          ..createdAt = s.createdAt;
      }).toList();

      await _repository.saveTask(task);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteSubTask(int taskId, String subtaskId) async {
    try {
      final task = await _repository.getTaskById(taskId);
      if (task == null) return;

      task.subtasks = task.subtasks
          .where((s) => s.subtaskId != subtaskId)
          .toList();
      await _repository.saveTask(task);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  //Dispose
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _calendarTimer?.cancel();
    _tasksSub?.cancel();
    super.dispose();
  }
}
