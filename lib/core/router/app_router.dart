import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:taskie/presentation/viewmodels/edit_name_view_model.dart';
import 'package:taskie/presentation/viewmodels/settings_view_model.dart';
import 'package:taskie/presentation/viewmodels/task_detail_view_model.dart';
import 'package:taskie/presentation/views/screens/onboarding_screen.dart';
import 'package:taskie/presentation/views/screens/settings_screen.dart';
import 'package:taskie/presentation/views/screens/splash_screen.dart';
import '../../presentation/views/screens/app_shell.dart';
import '../../presentation/views/screens/task_detail_screen.dart';
import '../../presentation/views/screens/task_archive_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',

  redirect: (context, state) {
    final settingsVM = context.read<SettingsViewModel>();
    final loc = state.matchedLocation;

    if (loc == '/splash') return null;

    final goingToOnboarding = loc == '/onboarding';

    if (!settingsVM.hasSeenOnboarding && !goingToOnboarding) {
      return '/onboarding';
    }
    if (settingsVM.hasSeenOnboarding && goingToOnboarding) {
      return '/';
    }
    return null;
  },

  routes: [
    GoRoute(path: '/splash', builder: (_, _) => SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, _) => OnboardingScreen()),

    GoRoute(
      path: '/settings',
      builder: (context, state) {
        final settingsVM = context.read<SettingsViewModel>();
        return ChangeNotifierProvider(
          create: (_) => EditNameViewModel(settingsVM.userName),
          child: SettingsScreen(),
        );
      },
    ),

    GoRoute(
      path: '/',
      builder: (_, _) => const AppShell(),
      routes: [
        GoRoute(path: 'archive', builder: (_, _) => const TaskArchiveScreen()),
        GoRoute(
          path: 'task/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id'] ?? '0');
            return ChangeNotifierProvider(
              create: (_) => TaskDetailViewModel(),
              child: TaskDetailScreen(taskId: id),
            );
          },
        ),
      ],
    ),
  ],
);
