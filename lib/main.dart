import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskie/app.dart';
import 'package:taskie/core/services/notification_service.dart';
import 'package:taskie/data/models/category.dart';
import 'package:taskie/data/models/task.dart';
import 'package:taskie/data/models/timetable_entry.dart';
import 'package:taskie/data/repositories/isar_task_repository.dart';
import 'package:taskie/data/repositories/isar_timetable_repository.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Timezone must be initialized before any scheduled notifications
  tz_data.initializeTimeZones();
  try {
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
  } catch (e) {
    debugPrint('Could not set local timezone: $e');
  }

  await NotificationService.instance.initialize();

  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open(
    [TaskSchema, CategorySchema, TimetableEntrySchema],
    directory: dir.path,
    name: 'taskie.db'
  );

  final repository = IsarTaskRepository(isar);
  await repository.seeDefaultCategories();

  final prefs = await SharedPreferences.getInstance();
  final timeTableRepository = IsarTimetableRepository(isar);

  runApp(TaskieApp(repository: repository, prefs: prefs, timetableRepository: timeTableRepository));

  unawaited(() async {
    final tasks = await isar.collection<Task>().where().findAll();
    final timetableEntries = await isar.timetableEntrys.where().findAll();
    await NotificationService.instance.restoreSavedReminders(
      tasks: tasks,
      timetableEntries: timetableEntries,
    );
  }());
}
