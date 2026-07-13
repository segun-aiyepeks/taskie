import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskie/core/constants/app_strings.dart';
import 'package:taskie/core/router/app_router.dart';
import 'package:taskie/core/theme/app_theme.dart';
import 'package:taskie/data/repositories/isar_timetable_repository.dart';
import 'package:taskie/data/repositories/task_repository.dart';
import 'package:taskie/presentation/viewmodels/app_shell_viewmodel.dart';
import 'package:taskie/presentation/viewmodels/category_view_model.dart';
import 'package:taskie/presentation/viewmodels/settings_view_model.dart';
import 'package:taskie/presentation/viewmodels/stats_viewmodel.dart';
import 'package:taskie/presentation/viewmodels/task_view_model.dart';
import 'package:taskie/presentation/viewmodels/timetable_view_model.dart';

class TaskieApp extends StatelessWidget {
  final TaskRepository repository;
  final SharedPreferences prefs;
  final IsarTimetableRepository timetableRepository;
  const TaskieApp({super.key, required this.repository, required this.prefs, required this.timetableRepository});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskViewModel(repository)),
        ChangeNotifierProvider(create: (_) => CategoryViewModel(repository)),
        ChangeNotifierProvider(create: (_) => StatsViewmodel(repository)),
        ChangeNotifierProvider(create: (_) => AppShellViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel(prefs)),
        ChangeNotifierProvider(create: (_) => TimetableViewModel(timetableRepository))
      ],
      child: _TaskieMaterialApp()
    );
  }
}

class _TaskieMaterialApp extends StatelessWidget {
  const _TaskieMaterialApp();

  @override
  Widget build(BuildContext context) {
    final settingsVM = context.watch<SettingsViewModel>();

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsVM.themeMode,
      routerConfig: appRouter,
      scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>()
    );
  }
}