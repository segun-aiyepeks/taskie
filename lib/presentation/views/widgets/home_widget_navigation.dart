import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:taskie/core/services/home_widget_service.dart';
import 'package:taskie/presentation/viewmodels/app_shell_viewmodel.dart';
import 'package:taskie/presentation/viewmodels/settings_view_model.dart';
import 'package:taskie/presentation/viewmodels/task_view_model.dart';
import 'package:taskie/presentation/viewmodels/timetable_view_model.dart';

/// Wait for onboarding, the splash route and task loading before handling a
/// cold launch. The same listener also handles taps while Taskie is running.
class HomeWidgetNavigation extends StatefulWidget {
  final Widget child;
  final GoRouter router;
  const HomeWidgetNavigation({
    super.key,
    required this.child,
    required this.router,
  });

  @override
  State<HomeWidgetNavigation> createState() => _HomeWidgetNavigationState();
}

class _HomeWidgetNavigationState extends State<HomeWidgetNavigation> {
  late HomeWidgetService _widgets;
  late TaskViewModel _tasks;
  bool _queued = false;

  @override
  void initState() {
    super.initState();
    _widgets = context.read<HomeWidgetService>();
    _tasks = context.read<TaskViewModel>();
    _widgets.addListener(_queueNavigation);
    _tasks.addListener(_queueNavigation);
    widget.router.routerDelegate.addListener(_queueNavigation);
    _queueNavigation();
  }

  void _queueNavigation() {
    if (_queued || !mounted) return;
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queued = false;
      if (!mounted || _widgets.pendingLaunch == null || _tasks.isLoading)
        return;
      final path = widget.router.routeInformationProvider.value.uri.path;
      if (path == '/splash' ||
          path == '/onboarding' ||
          !context.read<SettingsViewModel>().hasSeenOnboarding)
        return;
      final launch = _widgets.takeLaunch()!;
      if (launch.kind == HomeWidgetKind.task) {
        context.read<AppShellViewModel>().setIndex(0);
        final task = launch.taskId == null
            ? null
            : _tasks.getTaskbyId(launch.taskId!);
        widget.router.go(task == null ? '/' : '/task/${task.id}');
      } else {
        context.read<AppShellViewModel>().setIndex(2);
        final day = launch.weekday;
        context.read<TimetableViewModel>().selectDay(
          day != null && day >= 1 && day <= 7 ? day : DateTime.now().weekday,
        );
        widget.router.go('/');
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    _widgets.removeListener(_queueNavigation);
    _tasks.removeListener(_queueNavigation);
    widget.router.routerDelegate.removeListener(_queueNavigation);
    super.dispose();
  }
}
