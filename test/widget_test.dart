import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:taskie/app.dart';
import 'package:taskie/core/router/app_router.dart';
import 'package:taskie/core/utils/tutorial_keys.dart';
import 'package:taskie/data/models/category.dart';
import 'package:taskie/data/models/task.dart';
import 'package:taskie/data/models/timetable_entry.dart';
import 'package:taskie/data/repositories/task_repository.dart';
import 'package:taskie/data/repositories/timetable_repository.dart';
import 'package:taskie/presentation/viewmodels/app_shell_viewmodel.dart';
import 'package:taskie/presentation/viewmodels/settings_view_model.dart';
import 'package:taskie/presentation/views/screens/app_shell.dart';

class _Tasks implements TaskRepository {
  @override
  Stream<List<Task>> watchAllTasks() => Stream.value([]);
  @override
  Stream<List<Category>> watchAllCategories() => Stream.value([]);
  @override
  Stream<Map<String, int>> watchStats() => Stream.value({});
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Schedule implements TimetableRepository {
  @override
  Stream<List<TimetableEntry>> watchAllEntries() => Stream.value([]);
  @override
  Stream<List<TimetableEntry>> watchEntriesForDay(int dayOfWeek) =>
      Stream.value([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'first launch keeps the tutorial registered through onboarding and settings rebuilds',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        TaskieApp(
          repository: _Tasks(),
          prefs: prefs,
          timetableRepository: _Schedule(),
        ),
      );
      final tour = ShowcaseView.getNamed(TutorialKeys.scope);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      await tester.enterText(find.byType(TextField), 'Segun');
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.byType(AppShell), findsOneWidget);
      expect(ShowcaseView.getNamed(TutorialKeys.scope), same(tour));
      expect(tour.getActiveShowcaseKey, TutorialKeys.appTourSteps.first);

      final context = tester.element(find.byType(AppShell));
      final settings = context.read<SettingsViewModel>();
      await settings.setThemeMode(ThemeMode.dark);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(ShowcaseView.getNamed(TutorialKeys.scope), same(tour));
      tour.dismiss();
      await tester.pumpAndSettle();
      expect(settings.hasSeenTutorial, isTrue);
      expect(ShowcaseView.getNamed(TutorialKeys.scope), same(tour));
      expect(context.read<AppShellViewModel>().currentIndex, 0);

      // Replay the real tour through all four tabs after Settings has rebuilt.
      appRouter.push('/settings');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Replay the app tour'),
        300,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Replay the app tour'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      for (final key in TutorialKeys.appTourSteps) {
        expect(tour.getActiveShowcaseKey, key);
        expect(
          context.read<AppShellViewModel>().currentIndex,
          TutorialKeys.tabFor(key),
        );
        expect(tester.takeException(), isNull);
        tour.next();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pumpAndSettle();
      expect(tour.getActiveShowcaseKey, isNull);
      expect(ShowcaseView.getNamed(TutorialKeys.scope), same(tour));
      expect(context.read<AppShellViewModel>().currentIndex, 0);

      expect(
        find.widgetWithText(FloatingActionButton, 'Add Task'),
        findsOneWidget,
      );
      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();
      expect(find.text('New Task'), findsOneWidget);
      Navigator.of(tester.element(find.text('New Task'))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(FloatingActionButton, 'Add Schedule'),
        findsOneWidget,
      );
      await tester.tap(find.text('Add Schedule'));
      await tester.pumpAndSettle();
      expect(find.text('New schedule entry'), findsOneWidget);
      Navigator.of(tester.element(find.text('New schedule entry'))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(FloatingActionButton, 'Add Category'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'skipping onboarding starts the first-run tour without a missing scope',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      appRouter.go('/splash');
      await tester.pumpWidget(
        TaskieApp(
          repository: _Tasks(),
          prefs: prefs,
          timetableRepository: _Schedule(),
        ),
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.byType(AppShell), findsOneWidget);
      final tour = ShowcaseView.getNamed(TutorialKeys.scope);
      expect(tour.getActiveShowcaseKey, TutorialKeys.appTourSteps.first);
      tour.dismiss();
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
