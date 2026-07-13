// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskie/app.dart';
import 'package:taskie/data/models/category.dart';
import 'package:taskie/data/models/task.dart';
import 'package:taskie/data/repositories/isar_task_repository.dart';
import 'package:taskie/data/repositories/isar_timetable_repository.dart';


void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open(
    [TaskSchema, CategorySchema],
    directory: dir.path,
    name: 'taskie.db'
  );

    final repository = IsarTaskRepository(isar);
    await repository.seeDefaultCategories();

    final prefs = await SharedPreferences.getInstance();
    final timeTableRepository = IsarTimetableRepository(isar);

    await tester.pumpWidget(TaskieApp(repository: repository, prefs: prefs, timetableRepository: timeTableRepository,));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
