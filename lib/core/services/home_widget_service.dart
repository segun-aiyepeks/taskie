import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:taskie/data/models/task.dart';
import 'package:taskie/data/models/timetable_entry.dart';
import 'package:taskie/data/repositories/task_repository.dart';
import 'package:taskie/data/repositories/timetable_repository.dart';

enum HomeWidgetKind { task, schedule }

class HomeWidgetLaunch {
  final HomeWidgetKind kind;
  final int? taskId;
  final int? weekday;

  const HomeWidgetLaunch(this.kind, {this.taskId, this.weekday});

  static HomeWidgetLaunch? fromMap(Map<Object?, Object?>? data) {
    if (data == null) return null;
    return switch (data['kind']) {
      'task' => HomeWidgetLaunch(
        HomeWidgetKind.task,
        taskId: (data['id'] as num?)?.toInt(),
      ),
      'schedule' => HomeWidgetLaunch(
        HomeWidgetKind.schedule,
        weekday: (data['weekday'] as num?)?.toInt(),
      ),
      _ => null,
    };
  }
}

/// Publishes a local snapshot so Android can advance widgets without starting
/// Flutter. All timed pending tasks and all repeating entries are included.
class HomeWidgetService extends ChangeNotifier with WidgetsBindingObserver {
  static const channel = MethodChannel('com.aiyepeks.taskie/home_widgets');

  final TaskRepository _tasks;
  final TimetableRepository _schedule;
  StreamSubscription<List<Task>>? _taskSub;
  StreamSubscription<List<TimetableEntry>>? _scheduleSub;
  List<Task> _taskItems = [];
  List<TimetableEntry> _scheduleItems = [];
  bool _tasksLoaded = false;
  bool _scheduleLoaded = false;
  bool _disposed = false;
  bool _started = false;
  String? _pendingSnapshot;
  Future<void>? _write;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get isReady => _tasksLoaded && _scheduleLoaded;
  bool pinSupported = false;
  int taskWidgetCount = 0;
  int scheduleWidgetCount = 0;
  String? syncError;
  HomeWidgetLaunch? pendingLaunch;

  HomeWidgetService(this._tasks, this._schedule);

  void start() {
    if (_started || !isSupported) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    channel.setMethodCallHandler((call) async {
      if (call.method == 'widgetTapped') await _readLaunch();
    });
    _taskSub = _tasks.watchAllTasks().listen((tasks) {
      _taskItems = tasks;
      _tasksLoaded = true;
      unawaited(syncNow());
    }, onError: _onDataError);
    _scheduleSub = _schedule.watchAllEntries().listen((entries) {
      _scheduleItems = entries;
      _scheduleLoaded = true;
      unawaited(syncNow());
    }, onError: _onDataError);
    unawaited(refreshStatus());
    unawaited(_readLaunch());
  }

  void _onDataError(Object error) {
    syncError = 'Could not refresh widgets. Open Taskie again to retry.';
    _notify();
  }

  Future<bool> syncNow() async {
    if (_disposed || !isSupported || !isReady) return false;
    _pendingSnapshot = jsonEncode({
      'version': 1,
      'tasks': [
        for (final task in _taskItems)
          if (task.isPending && task.dueDate != null)
            {
              'id': task.id,
              'title': task.title,
              'dueAt': task.dueDate!.millisecondsSinceEpoch,
            },
      ],
      'schedule': [
        for (final entry in _scheduleItems)
          {
            'id': entry.id,
            'title': entry.title,
            'days': entry.daysOfWeek,
            'startMinutes': entry.startMinutes,
            'endMinutes': entry.endMinutes,
          },
      ],
    });
    // Coalesce rapid changes and serialize writes so an older snapshot cannot
    // overwrite a task completion or deletion that arrived while saving.
    _write ??= _flush();
    await _write;
    return syncError == null && !_disposed;
  }

  Future<void> _flush() async {
    // Yield before touching _write so the caller can assign the Future first.
    await Future<void>.value();
    try {
      while (!_disposed && _pendingSnapshot != null) {
        final snapshot = _pendingSnapshot!;
        _pendingSnapshot = null;
        await channel.invokeMethod<void>('updateSnapshot', snapshot);
        syncError = null;
      }
    } on PlatformException catch (_) {
      syncError = 'Could not refresh widgets. Tap Add again to retry.';
    } on MissingPluginException catch (_) {
      syncError = 'Install the updated Android app to use home screen widgets.';
    } finally {
      _write = null;
      _notify();
    }
  }

  Future<void> refreshStatus() async {
    if (!isSupported || _disposed) return;
    try {
      final status = await channel.invokeMapMethod<String, dynamic>(
        'getStatus',
      );
      if (_disposed) return;
      pinSupported = status?['pinSupported'] == true;
      taskWidgetCount = (status?['taskCount'] as num?)?.toInt() ?? 0;
      scheduleWidgetCount = (status?['scheduleCount'] as num?)?.toInt() ?? 0;
      _notify();
    } on PlatformException catch (_) {
      // Manual placement from the Android widget picker is still available.
    } on MissingPluginException catch (_) {
      syncError = 'Install the updated Android app to use home screen widgets.';
      _notify();
    }
  }

  /// True means the launcher accepted the request, not that the user added it.
  Future<bool> requestPin(HomeWidgetKind kind) async {
    if (!await syncNow()) return false;
    await refreshStatus();
    if (!pinSupported || _disposed) return false;
    return await channel.invokeMethod<bool>('requestPin', kind.name) ?? false;
  }

  Future<void> _readLaunch() async {
    if (_disposed) return;
    try {
      final launch = await channel.invokeMapMethod<Object?, Object?>(
        'consumeLaunch',
      );
      if (_disposed) return;
      final parsed = HomeWidgetLaunch.fromMap(launch);
      if (parsed != null) {
        pendingLaunch = parsed;
        _notify();
      }
    } on PlatformException catch (_) {
      // A regular app launch has no widget destination.
    } on MissingPluginException catch (_) {
      // Supported only by the Android host.
    }
  }

  HomeWidgetLaunch? takeLaunch() {
    final launch = pendingLaunch;
    pendingLaunch = null;
    return launch;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshStatus());
      unawaited(syncNow());
      unawaited(_readLaunch());
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _taskSub?.cancel();
    _scheduleSub?.cancel();
    if (_started) {
      WidgetsBinding.instance.removeObserver(this);
      channel.setMethodCallHandler(null);
    }
    super.dispose();
  }
}
