import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:taskie/presentation/viewmodels/settings_view_model.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../widgets/developer_credit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNextRoute();
  }

  Future<void> _decideNextRoute() async {
    // A short, deliberate minimum display time. Without this, on fast
    // devices the splash could flash for only a few milliseconds —
    // long enough to feel like a glitch, not a brand moment.
    await Future.delayed(const Duration(milliseconds: 5000));
    if (!mounted) return;

    final settingsVM = context.read<SettingsViewModel>();
    context.go(settingsVM.hasSeenOnboarding ? '/' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              Image.asset(
                'assets/icons/logo_mark.png',
                width: 76,
                height: 76,
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                AppStrings.appName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(flex: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: AppSizes.xl),
                child: DeveloperCredit(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}