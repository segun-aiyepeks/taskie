import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:taskie/presentation/viewmodels/onboarding_view_model.dart';
import 'package:taskie/presentation/viewmodels/settings_view_model.dart';
import 'package:taskie/presentation/views/widgets/developer_credit.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final obVM  = context.watch<OnboardingViewModel>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Logo, top-left ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding, AppSizes.md, AppSizes.pagePadding, 0,
              ),
              child: Row(
                children: [
                  Image.asset(
                  'assets/icons/logo_mark.png',
                  width: 28, height: 28,
                ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.appName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // ── Skip ─────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.sm),
                child: obVM.isLastPage
                    ? const SizedBox(height: 40)
                    : TextButton(
                        onPressed: () => _skip(context),
                        child: Text(
                          AppStrings.skip,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
            ),

            // ── Pages ────────────────────────────────────
            Expanded(
              child: PageView(
                controller: obVM.pageController,
                onPageChanged: obVM.onPageChanged,
                children: [
                  _IntroPage(
                    icon: Icons.task_alt_rounded,
                    title: AppStrings.ob1Title,
                    subtitle: AppStrings.ob1Sub,
                  ),
                  _IntroPage(
                    icon: Icons.folder_copy_rounded,
                    title: AppStrings.ob2Title,
                    subtitle: AppStrings.ob2Sub,
                  ),
                  _IntroPage(
                    icon: Icons.cloud_off_rounded,
                    title: AppStrings.ob3Title,
                    subtitle: AppStrings.ob3Sub,
                  ),
                  const _NamePage(),
                ],
              ),
            ),

            //Developer Credit
            const SizedBox(height: AppSizes.sm),
            const Center(child: DeveloperCredit()),

            // ── Dots ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  OnboardingViewModel.pageCount,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: obVM.currentPage == i ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: obVM.currentPage == i
                          ? AppColors.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom button ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding, 0,
                AppSizes.pagePadding, AppSizes.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => obVM.isLastPage
                      ? _finish(context, obVM)
                      : obVM.onNextPage(),
                  child: Text(
                    obVM.isLastPage ? AppStrings.getStarted : 'Next',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _skip(BuildContext context) {
    context.read<SettingsViewModel>().completeOnboarding();
    context.go('/');
  }

  void _finish(BuildContext context, OnboardingViewModel obVM) {
    final settingsVM = context.read<SettingsViewModel>();
    final name = obVM.nameController.text.trim();
    if (name.isNotEmpty) settingsVM.setUserName(name);
    settingsVM.completeOnboarding();
    context.go('/');
  }
}

// ── Intro slide ──────────────────────────────────────────────
class _IntroPage extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   subtitle;

  const _IntroPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      // ClampingScrollPhysics avoids the bounce-overscroll glow when
      // content actually fits — it only scrolls when it has to.
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xl,
        vertical: AppSizes.lg,
      ),
      child: ConstrainedBox(
        // Forces the column to be at least as tall as the available
        // space, so it still visually centers when there's room —
        // but lets it grow taller (and scroll) when there isn't.
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.45,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: AppSizes.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Name capture page ────────────────────────────────────────
class _NamePage extends StatelessWidget {
  const _NamePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final obVM  = context.watch<OnboardingViewModel>();

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xl,
        vertical: AppSizes.lg,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.45,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.waving_hand_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            Text(
              AppStrings.onboardingNameTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              AppStrings.onboardingNameSub,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            TextField(
              controller: obVM.nameController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: AppStrings.nameHint),
            ),
          ],
        ),
      ),
    );
  }
}