import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:taskie/core/constants/app_strings.dart';
import 'package:taskie/core/services/home_widget_service.dart';
import 'package:taskie/presentation/views/widgets/home_widget_navigation.dart';
import 'package:taskie/core/router/app_router.dart';
import 'package:taskie/core/theme/app_theme.dart';
import 'package:taskie/core/utils/tutorial_keys.dart';
import 'package:taskie/data/repositories/timetable_repository.dart';
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
  final TimetableRepository timetableRepository;
  const TaskieApp({
    super.key,
    required this.repository,
    required this.prefs,
    required this.timetableRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          lazy: false,
          create: (_) =>
              HomeWidgetService(repository, timetableRepository)..start(),
        ),
        ChangeNotifierProvider(create: (_) => TaskViewModel(repository)),
        ChangeNotifierProvider(create: (_) => CategoryViewModel(repository)),
        ChangeNotifierProvider(create: (_) => StatsViewmodel(repository)),
        ChangeNotifierProvider(create: (_) => AppShellViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel(prefs)),
        ChangeNotifierProvider(
          create: (_) => TimetableViewModel(timetableRepository),
        ),
      ],
      // Own the tour above MaterialApp so onboarding/theme rebuilds cannot
      // dispose an old controller after a replacement registers the same scope.
      child: const _TaskieShowcaseScope(child: _TaskieMaterialApp()),
    );
  }
}

class _TaskieMaterialApp extends StatefulWidget {
  const _TaskieMaterialApp();

  @override
  State<_TaskieMaterialApp> createState() => _TaskieMaterialAppState();
}

class _TaskieMaterialAppState extends State<_TaskieMaterialApp> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
      builder: (context, child) => HomeWidgetNavigation(
        router: appRouter,
        child: child ?? const SizedBox.shrink(),
      ),
      scaffoldMessengerKey: _scaffoldMessengerKey,
    );
  }
}

/// Keeps one named showcase controller alive around the router's Navigator.
/// A stable scope is required because the first-run tour spans several tabs.
class _TaskieShowcaseScope extends StatefulWidget {
  final Widget child;

  const _TaskieShowcaseScope({required this.child});

  @override
  State<_TaskieShowcaseScope> createState() => _TaskieShowcaseScopeState();
}

class _TaskieShowcaseScopeState extends State<_TaskieShowcaseScope> {
  late final ShowcaseView _showcaseView;

  @override
  void initState() {
    super.initState();
    _showcaseView = ShowcaseView.register(
      scope: TutorialKeys.scope,
      enableAutoScroll: true,
      onFinish: _finishTutorial,
      onDismiss: (_) => _finishTutorial(),
      onStart: (_, key) {
        final tabIndex = TutorialKeys.tabFor(key);
        if (tabIndex != null && mounted) {
          context.read<AppShellViewModel>().setIndex(tabIndex);
        }
      },
    );
  }

  void _finishTutorial() {
    if (!mounted) return;
    context.read<SettingsViewModel>().completeTutorial();
    context.read<AppShellViewModel>().setIndex(0);
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    _showcaseView.unregister();
    super.dispose();
  }
}
