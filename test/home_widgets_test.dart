import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskie/core/constants/app_enums.dart';
import 'package:taskie/core/services/home_widget_service.dart';
import 'package:taskie/data/models/task.dart';
import 'package:taskie/data/models/timetable_entry.dart';
import 'package:taskie/data/repositories/task_repository.dart';
import 'package:taskie/data/repositories/timetable_repository.dart';
import 'package:taskie/presentation/viewmodels/app_shell_viewmodel.dart';
import 'package:taskie/presentation/viewmodels/settings_view_model.dart';
import 'package:taskie/presentation/viewmodels/task_view_model.dart';
import 'package:taskie/presentation/viewmodels/timetable_view_model.dart';
import 'package:taskie/presentation/views/widgets/home_widget_navigation.dart';
import 'package:taskie/presentation/views/widgets/home_widgets_section.dart';

class _Tasks implements TaskRepository {
  final changes = StreamController<List<Task>>.broadcast(sync: true);
  @override
  Stream<List<Task>> watchAllTasks() => changes.stream;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Schedule implements TimetableRepository {
  final changes = StreamController<List<TimetableEntry>>.broadcast(sync: true);
  @override
  Stream<List<TimetableEntry>> watchAllEntries() => changes.stream;
  @override
  Stream<List<TimetableEntry>> watchEntriesForDay(int dayOfWeek) =>
      Stream.value([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Task _task(int id, {bool completed = false, bool timed = true}) => Task()
  ..id = id
  ..title = 'Task $id'
  ..priority = Priority.medium
  ..dueDate = timed ? DateTime(2026, 11, 1, 10 + id) : null
  ..status = completed ? TaskStatus.completed : TaskStatus.pending;

TimetableEntry _entry() => TimetableEntry()
  ..id = 1
  ..title = 'Weekly planning'
  ..daysOfWeek = [1, 3, 5]
  ..startMinutes = 9 * 60
  ..endMinutes = 10 * 60
  ..colorHex = '#4F67F8'
  ..isHighPriority = false;

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late _Tasks tasks;
  late _Schedule schedule;
  late HomeWidgetService service;
  late List<Map<String, dynamic>> snapshots;
  late List<MethodCall> calls;
  Map<String, Object>? launch;
  Completer<void>? firstWrite;
  bool pinSupported = true;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tasks = _Tasks();
    schedule = _Schedule();
    service = HomeWidgetService(tasks, schedule);
    snapshots = [];
    calls = [];
    launch = null;
    firstWrite = null;
    pinSupported = true;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      HomeWidgetService.channel,
      (call) async {
        calls.add(call);
        switch (call.method) {
          case 'updateSnapshot':
            snapshots.add(
              jsonDecode(call.arguments as String) as Map<String, dynamic>,
            );
            if (snapshots.length == 1) await firstWrite?.future;
            return null;
          case 'getStatus':
            return {
              'pinSupported': pinSupported,
              'taskCount': 0,
              'scheduleCount': 0,
            };
          case 'consumeLaunch':
            final target = launch;
            launch = null;
            return target;
          case 'requestPin':
            return true;
        }
        return null;
      },
    );
  });

  tearDown(() async {
    service.dispose();
    if (firstWrite != null && !firstWrite!.isCompleted) firstWrite!.complete();
    await tasks.changes.close();
    await schedule.changes.close();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      HomeWidgetService.channel,
      null,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  Future<void> publish([
    List<Task> taskItems = const [],
    List<TimetableEntry> entries = const [],
  ]) async {
    tasks.changes.add(taskItems);
    schedule.changes.add(entries);
    await service.syncNow();
    await service.refreshStatus();
  }

  test(
    'snapshot waits for both repositories and contains only timed unfinished tasks',
    () async {
      service.start();
      tasks.changes.add([
        _task(1),
        _task(2, completed: true),
        _task(3, timed: false),
      ]);
      expect(await service.syncNow(), isFalse);
      expect(snapshots, isEmpty);
      schedule.changes.add([_entry()]);
      expect(await service.syncNow(), isTrue);
      final snapshot = snapshots.last;
      expect(snapshot['version'], 1);
      expect((snapshot['tasks'] as List).map((t) => t['id']), [1]);
      expect(
        snapshot['tasks'][0]['dueAt'],
        _task(1).dueDate!.millisecondsSinceEpoch,
      );
      expect(snapshot['schedule'][0]['days'], [1, 3, 5]);
      expect(snapshot['schedule'][0]['startMinutes'], 540);
      // A schedule belongs in its widget even when its alarm is switched off.
      expect(snapshot['schedule'][0]['title'], 'Weekly planning');
      expect(calls.where((call) => call.method == 'requestPin'), isEmpty);
    },
  );

  test(
    'completing and deleting entries clears their widget snapshot',
    () async {
      service.start();
      await publish([_task(1)], [_entry()]);
      await publish([_task(1, completed: true)], []);
      expect(snapshots.last['tasks'], isEmpty);
      expect(snapshots.last['schedule'], isEmpty);
      await publish();
      expect(snapshots.last['tasks'], isEmpty);
    },
  );

  test(
    'rapid changes cannot be overwritten by an older snapshot in flight',
    () async {
      firstWrite = Completer<void>();
      service.start();
      tasks.changes.add([_task(1)]);
      schedule.changes.add([]);
      await Future<void>.delayed(Duration.zero);
      expect(snapshots.length, 1);
      tasks.changes.add([]);
      final finished = service.syncNow();
      firstWrite!.complete();
      expect(await finished, isTrue);
      expect(snapshots.length, 2);
      expect(snapshots.last['tasks'], isEmpty);
    },
  );

  test(
    'pinning is explicit and unsupported launchers return the manual option',
    () async {
      service.start();
      await publish();
      expect(calls.where((call) => call.method == 'requestPin'), isEmpty);
      expect(await service.requestPin(HomeWidgetKind.task), isTrue);
      expect(calls.last.arguments, 'task');
      expect(
        service.taskWidgetCount,
        0,
      ); // A request is not proof of user approval.
      pinSupported = false;
      expect(await service.requestPin(HomeWidgetKind.schedule), isFalse);
      expect(calls.where((call) => call.method == 'requestPin').length, 1);
    },
  );

  test('widget destinations survive startup and are consumed once', () async {
    launch = {'kind': 'task', 'id': 12};
    service.start();
    await publish();
    expect(service.pendingLaunch?.taskId, 12);
    expect(service.takeLaunch()?.kind, HomeWidgetKind.task);
    expect(service.takeLaunch(), isNull);
    expect(HomeWidgetLaunch.fromMap({'kind': 'unknown'}), isNull);
  });

  testWidgets(
    'Settings requests the chosen widget without claiming it was installed',
    (tester) async {
      service.start();
      await publish();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: service,
          child: MaterialApp(
            home: Scaffold(
              body: ListView(children: const [HomeWidgetsSection()]),
            ),
          ),
        ),
      );
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Add to home screen').first,
      );
      await tester.pumpAndSettle();
      expect(
        calls.where((call) => call.method == 'requestPin').single.arguments,
        'task',
      );
      expect(
        find.text('Confirm the widget placement on your home screen.'),
        findsOneWidget,
      );
      expect(find.text('1 on your home screen'), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets(
    'Settings explains manual placement when the launcher cannot pin',
    (tester) async {
      pinSupported = false;
      service.start();
      await publish();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: service,
          child: MaterialApp(
            home: Scaffold(
              body: ListView(children: const [HomeWidgetsSection()]),
            ),
          ),
        ),
      );
      final button = find.widgetWithText(OutlinedButton, 'How to add').last;
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.textContaining('Taskie: Next schedule'), findsOneWidget);
      expect(calls.where((call) => call.method == 'requestPin'), isEmpty);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets(
    'cold task taps wait for splash; warm schedule taps select the correct day',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsViewModel(await SharedPreferences.getInstance());
      await settings.completeOnboarding();
      final taskVM = TaskViewModel(
        tasks,
        clock: () => DateTime(2026, 10, 28, 12),
      );
      final scheduleVM = TimetableViewModel(schedule);
      final shell = AppShellViewModel();
      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (_, _) => const Text('Loading app'),
          ),
          GoRoute(path: '/', builder: (_, _) => const Text('Home')),
          GoRoute(
            path: '/task/:id',
            builder: (_, state) =>
                Text('Task detail ${state.pathParameters['id']}'),
          ),
        ],
      );
      addTearDown(settings.dispose);
      addTearDown(scheduleVM.dispose);
      addTearDown(shell.dispose);
      addTearDown(router.dispose);
      launch = {'kind': 'task', 'id': 1};
      service.start();
      await publish([_task(1)], [_entry()]);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: service),
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: taskVM),
            ChangeNotifierProvider.value(value: scheduleVM),
            ChangeNotifierProvider.value(value: shell),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            builder: (_, child) =>
                HomeWidgetNavigation(router: router, child: child!),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Loading app'), findsOneWidget);
      expect(service.pendingLaunch, isNotNull);
      router.go('/');
      await tester.pumpAndSettle();
      expect(find.text('Task detail 1'), findsOneWidget);
      launch = {'kind': 'schedule', 'weekday': 5};
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(shell.currentIndex, 2);
      expect(scheduleVM.selectedDay, 5);
      await tester.pumpWidget(const SizedBox.shrink());
      taskVM.dispose();
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
