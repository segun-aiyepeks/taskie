import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taskie/core/constants/app_enums.dart';
import 'package:taskie/core/utils/date_utils.dart';
import 'package:taskie/data/models/category.dart';
import 'package:taskie/data/models/task.dart';
import 'package:taskie/data/repositories/task_repository.dart';
import 'package:taskie/presentation/viewmodels/add_taskviemodel.dart';
import 'package:taskie/presentation/viewmodels/category_view_model.dart';
import 'package:taskie/presentation/viewmodels/task_view_model.dart';
import 'package:taskie/presentation/views/screens/task_archive_screen.dart';
import 'package:taskie/presentation/views/widgets/add_task_sheet.dart';
import 'package:taskie/presentation/views/widgets/task_card.dart';

Task task(int id, {DateTime? due, DateTime? created, bool completed = false}) =>
    Task()
      ..id = id
      ..title = 'Task $id'
      ..priority = Priority.medium
      ..createdAt = created ?? DateTime(2026, 10, 28, 8)
      ..dueDate = due
      ..status = completed ? TaskStatus.completed : TaskStatus.pending;

class _Repository implements TaskRepository {
  final changes = StreamController<List<Task>>.broadcast(sync: true);

  @override
  Stream<List<Task>> watchAllTasks() => changes.stream;

  @override
  Stream<List<Category>> watchAllCategories() => Stream.value([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Fixture {
  DateTime now;
  final repository = _Repository();
  late final TaskViewModel vm;
  bool _disposed = false;

  _Fixture(this.now, List<Task> tasks) {
    vm = TaskViewModel(repository, clock: () => now);
    repository.changes.add(tasks);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    vm.dispose();
    await repository.changes.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'previous days use the scheduled day, or the creation day without a date',
    () {
      final now = DateTime(2026, 10, 28, 12);
      final scheduled = task(
        1,
        due: DateTime(2026, 10, 29, 9),
        created: DateTime(2026, 1, 1),
      );
      expect(scheduled.isPreviousAt(now), isFalse);
      expect(scheduled.isScheduledFor(DateTime(2026, 10, 29)), isTrue);

      final undated = task(2, created: DateTime(2026, 10, 27, 23, 59));
      expect(undated.scheduledDay, DateTime(2026, 10, 27));
      expect(undated.isPreviousAt(now), isTrue);
      expect(undated.isExpiredAt(now), isTrue);
      expect(task(3).isScheduledFor(now), isTrue);
      expect(task(3).isExpiredAt(now), isFalse);
    },
  );

  test(
    'expiry starts at the next local day; reminder time does not expire tasks',
    () {
      final deadline = DateTime(2026, 10, 28, 12);
      final pending = task(1, due: deadline);
      expect(
        pending.isExpiredAt(deadline.subtract(const Duration(microseconds: 1))),
        isFalse,
      );
      expect(pending.isExpiredAt(deadline), isFalse);
      expect(
        pending.isExpiredAt(DateTime(2026, 10, 28, 23, 59, 59, 999, 999)),
        isFalse,
      );
      expect(pending.isExpiredAt(DateTime(2026, 10, 29)), isTrue);
      expect(pending.isPreviousAt(deadline), isFalse);
      final completed = task(2, due: deadline, completed: true);
      expect(completed.isExpiredAt(DateTime(2026, 11, 1)), isFalse);
      expect(completed.isPreviousAt(DateTime(2026, 11, 1)), isTrue);
      expect(completed.isCompleted, isTrue);
    },
  );

  test('calendar boundaries work across years and for UTC reminders', () {
    final old = task(1, due: DateTime(2026, 12, 31, 23, 59));
    expect(old.isPreviousAt(DateTime(2027, 1, 1)), isTrue);
    final localDeadline = DateTime(2026, 10, 28, 1);
    final utcTask = task(2, due: localDeadline.toUtc());
    expect(utcTask.scheduledDay, DateTime(2026, 10, 28));
    expect(utcTask.isExpiredAt(localDeadline), isFalse);
    expect(utcTask.isExpiredAt(DateTime(2026, 10, 29)), isTrue);
  });

  testWidgets(
    'Today stays fresh and Expired explicitly shows unfinished archived tasks',
    (tester) async {
      final previous = task(1, due: DateTime(2026, 10, 27, 10));
      final previousDone = task(
        2,
        due: DateTime(2026, 10, 26, 10),
        completed: true,
      );
      final today = task(3);
      final earlierToday = task(4, due: DateTime(2026, 10, 28, 9));
      final upcoming = task(5, due: DateTime(2026, 10, 29, 9));
      final done = task(6, due: DateTime(2026, 10, 28, 10), completed: true);
      final fixture = _Fixture(DateTime(2026, 10, 28, 12), [
        previous,
        previousDone,
        today,
        earlierToday,
        upcoming,
        done,
      ]);
      addTearDown(fixture.dispose);
      expect(fixture.vm.activeFilter, TaskFilter.all);
      expect(
        fixture.vm.filteredTasks.map((t) => t.id),
        unorderedEquals([3, 4, 5, 6]),
      );
      fixture.vm.setFilter(TaskFilter.today);
      expect(
        fixture.vm.filteredTasks.map((t) => t.id),
        unorderedEquals([3, 4, 6]),
      );
      expect(fixture.vm.todayCompletedCount, 1);
      fixture.vm.setFilter(TaskFilter.all);
      expect(
        fixture.vm.filteredTasks.map((t) => t.id),
        unorderedEquals([3, 4, 5, 6]),
      );
      fixture.vm.setFilter(TaskFilter.expired);
      expect(fixture.vm.filteredTasks, [previous]);
      fixture.vm.setFilter(TaskFilter.completed);
      expect(fixture.vm.filteredTasks, [done]);
      fixture.vm.setFilter(TaskFilter.pending);
      expect(
        fixture.vm.filteredTasks.map((t) => t.id),
        unorderedEquals([3, 4, 5]),
      );
      fixture.vm.setSearchQuery('missing');
      fixture.vm.setFilterCategory(99);
      expect(fixture.vm.archivedTasksByDate.keys, [
        DateTime(2026, 10, 27),
        DateTime(2026, 10, 26),
      ]);
      expect(fixture.vm.archivedCount, 2);
      await fixture.dispose();
    },
  );

  testWidgets(
    'midnight archives finished and unfinished tasks and reveals the new day',
    (tester) async {
      final unfinished = task(1, created: DateTime(2026, 12, 31, 8));
      final finished = task(
        2,
        due: DateTime(2026, 12, 31, 18),
        completed: true,
      );
      final planned = task(3, due: DateTime(2027, 1, 1, 10));
      final fixture = _Fixture(DateTime(2026, 12, 31, 23, 59, 59), [
        unfinished,
        finished,
        planned,
      ]);
      addTearDown(fixture.dispose);
      expect(fixture.vm.todayCount, 2);
      fixture.vm.setFilter(TaskFilter.all);
      fixture.now = DateTime(2027, 1, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(fixture.vm.activeFilter, TaskFilter.all);
      expect(fixture.vm.filteredTasks, [planned]);
      expect(fixture.vm.archivedCount, 2);
      expect(
        fixture.vm.archivedTasksByDate[DateTime(2026, 12, 31)],
        containsAll([unfinished, finished]),
      );
      expect(unfinished.status, TaskStatus.pending);
      expect(finished.status, TaskStatus.completed);
      fixture.now = DateTime(2027, 1, 2);
      fixture.vm.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(fixture.vm.filteredTasks, isEmpty);
      expect(fixture.vm.archivedCount, 3);
      await fixture.dispose();
    },
  );

  testWidgets(
    'home keeps future tasks grouped by date when today is empty and days change',
    (tester) async {
      final archived = task(1, due: DateTime(2026, 12, 30))..categoryId = 1;
      final tomorrow = task(2, due: DateTime(2027, 1, 1, 10))..categoryId = 1;
      final nextWeek = task(3, due: DateTime(2027, 1, 7, 9))..categoryId = 2;
      final sameDay = task(4, due: DateTime(2027, 1, 1, 8))..categoryId = 1;
      final fixture = _Fixture(DateTime(2026, 12, 31, 12), [
        nextWeek,
        archived,
        tomorrow,
        sameDay,
      ]);
      addTearDown(fixture.dispose);

      expect(fixture.vm.todayCount, 0);
      expect(fixture.vm.activeFilter, TaskFilter.all);
      fixture.vm.setSortOption(TaskSortOption.dueDate);
      expect(fixture.vm.filteredTasksByDate.keys, [
        DateTime(2027, 1, 1),
        DateTime(2027, 1, 7),
      ]);
      expect(fixture.vm.filteredTasksByDate[DateTime(2027, 1, 1)], [
        sameDay,
        tomorrow,
      ]);
      expect(fixture.vm.currentTasks.where((t) => t.categoryId == 1).length, 2);

      fixture.vm.setFilterCategory(2);
      expect(fixture.vm.filteredTasksByDate.values.single, [nextWeek]);
      fixture.vm.setSearchQuery('missing');
      expect(fixture.vm.filteredTasksByDate, isEmpty);
      fixture.vm.clearFilters();
      expect(fixture.vm.activeFilter, TaskFilter.all);
      expect(fixture.vm.filteredTasksByDate.length, 2);

      fixture.vm.setFilter(TaskFilter.today);
      expect(fixture.vm.filteredTasksByDate, isEmpty);
      fixture.now = DateTime(2027, 1, 2);
      fixture.vm.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(fixture.vm.activeFilter, TaskFilter.all);
      expect(fixture.vm.filteredTasksByDate, {
        DateTime(2027, 1, 7): [nextWeek],
      });
      expect(fixture.vm.currentTasks.where((t) => t.categoryId == 1), isEmpty);
      expect(fixture.vm.archivedCount, 3);
      await fixture.dispose();
    },
  );

  testWidgets(
    'reopening the app and rescheduling a previous task refresh the correct day',
    (tester) async {
      final previous = task(1, due: DateTime(2026, 10, 27, 9));
      final fixture = _Fixture(DateTime(2026, 10, 28, 12), [previous]);
      addTearDown(fixture.dispose);
      expect(fixture.vm.archivedCount, 1);
      previous.dueDate = DateTime(2026, 10, 28, 16);
      fixture.repository.changes.add([previous]);
      expect(fixture.vm.archivedCount, 0);
      expect(fixture.vm.filteredTasks, [previous]);
      fixture.now = DateTime(2026, 11, 5);
      fixture.vm.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(
        fixture.vm.archivedTasksByDate.keys.single,
        DateTime(2026, 10, 28),
      );
      expect(fixture.vm.todayCount, 0);
      await fixture.dispose();
    },
  );

  testWidgets(
    'a visible task stays Pending after its time and becomes Expired at midnight',
    (tester) async {
      final item = task(1, due: DateTime(2026, 10, 28, 12));
      final fixture = _Fixture(DateTime(2026, 10, 28, 11, 59, 59), [item]);
      final categories = CategoryViewModel(fixture.repository);
      addTearDown(fixture.dispose);
      addTearDown(categories.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: fixture.vm),
            ChangeNotifierProvider.value(value: categories),
          ],
          child: MaterialApp(
            home: Scaffold(body: TaskCard(task: item)),
          ),
        ),
      );
      expect(find.text('Pending'), findsOneWidget);
      fixture.now = DateTime(2026, 10, 28, 12);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Expired'), findsNothing);
      expect(fixture.vm.archivedCount, 0);
      fixture.now = DateTime(2026, 10, 28, 23, 59, 59);
      fixture.vm.refreshTime();
      await tester.pump();
      expect(find.text('Pending'), findsOneWidget);
      fixture.now = DateTime(2026, 10, 29);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Expired'), findsOneWidget);
      expect(fixture.vm.archivedCount, 1);
      expect(fixture.vm.filteredTasks, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await fixture.dispose();
    },
  );

  testWidgets(
    'Archive shows dates and completion filters and can select an older day',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = _Fixture(DateTime(2026, 10, 28, 12), [
        task(1, due: DateTime(2026, 10, 27, 9)),
        task(2, due: DateTime(2026, 10, 27, 10), completed: true),
        task(3, due: DateTime(2026, 10, 26, 9)),
        task(4, due: DateTime(2026, 10, 29, 9)),
      ]);
      final categories = CategoryViewModel(fixture.repository);
      addTearDown(fixture.dispose);
      addTearDown(categories.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: fixture.vm),
            ChangeNotifierProvider.value(value: categories),
          ],
          child: const MaterialApp(home: TaskArchiveScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(DateHelper.fullDate(DateTime(2026, 10, 27))),
        findsOneWidget,
      );
      expect(find.text('Task 4'), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Not completed'));
      await tester.pumpAndSettle();
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2'), findsNothing);
      expect(find.text('Expired'), findsWidgets);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
      await tester.pumpAndSettle();
      expect(find.text('Task 2'), findsOneWidget);
      expect(find.text('Task 1'), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, 'All tasks'));
      await tester.tap(find.text('All dates'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('26'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Task 3'), findsOneWidget);
      expect(find.text('Task 1'), findsNothing);
      await tester.tap(find.text('Clear date'));
      await tester.pumpAndSettle();
      expect(find.text('Task 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await fixture.dispose();
    },
  );

  testWidgets(
    'archived tasks can open the date picker and keep a midnight reminder when edited',
    (tester) async {
      final oldTask = task(1, due: DateTime(2020, 1, 15));
      final form = AddTaskViewModel(existingTask: oldTask);
      expect(form.fullDueDate, oldTask.dueDate);
      form.dispose();
      final repository = _Repository();
      final categories = CategoryViewModel(repository);
      addTearDown(categories.dispose);
      addTearDown(repository.changes.close);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: categories,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () =>
                        showAddTaskSheet(context, existingTask: oldTask),
                    child: const Text('Edit old task'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Edit old task'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byIcon(Icons.calendar_today_rounded));
      await tester.tap(find.byIcon(Icons.calendar_today_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
