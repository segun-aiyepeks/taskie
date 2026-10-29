import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:taskie/presentation/viewmodels/edit_name_view_model.dart';
import 'package:taskie/presentation/viewmodels/settings_view_model.dart';
import 'package:taskie/presentation/viewmodels/app_shell_viewmodel.dart';
import 'package:taskie/core/utils/tutorial_keys.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/notification_service.dart';
import '../widgets/home_widgets_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsVM = context.watch<SettingsViewModel>();
    final editVM = context.watch<EditNameViewModel>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        children: [
          // ── Avatar ───────────────────────────────────
          Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(
                settingsVM.initials,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSizes.xl),

          // ── Name editor ──────────────────────────────
          Text(
            'Your name',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: editVM.nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Enter your name',
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              IconButton.filled(
                onPressed: () {
                  settingsVM.setUserName(editVM.nameController.text);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Name updated')));
                },
                icon: const Icon(Icons.check_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.xl),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: AppSizes.xl),

          // ── Theme picker ─────────────────────────────
          Text(
            'Appearance',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          _ThemeOption(
            label: 'System default',
            mode: ThemeMode.system,
            current: settingsVM.themeMode,
            onSelect: settingsVM.setThemeMode,
          ),
          _ThemeOption(
            label: 'Light',
            mode: ThemeMode.light,
            current: settingsVM.themeMode,
            onSelect: settingsVM.setThemeMode,
          ),
          _ThemeOption(
            label: 'Dark',
            mode: ThemeMode.dark,
            current: settingsVM.themeMode,
            onSelect: settingsVM.setThemeMode,
          ),
          const SizedBox(height: AppSizes.xl),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: AppSizes.lg),

          const HomeWidgetsSection(),
          const SizedBox(height: AppSizes.xl),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: AppSizes.lg),

          Text(
            'Notifications',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test notifications',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sends a test notification in 10 seconds. '
                  'Lock your screen after tapping to confirm it arrives.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final scheduled = await NotificationService.instance
                          .sendTestNotification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              scheduled
                                  ? 'Test alarm scheduled — turn up your alarm volume and lock your screen.'
                                  : 'Could not schedule the test alarm. Check Taskie notification and exact-alarm access in Android Settings.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.notifications_outlined, size: 18),
                    label: const Text('Send test notification'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          // Exact alarm permission button (Android 12+)
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exact alarm permission',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Allows reminders to fire at the exact time. Without it, '
                  'Android may deliver them a little late.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await NotificationService.instance
                          .requestExactAlarmPermission();
                    },
                    icon: const Icon(Icons.alarm_outlined, size: 18),
                    label: const Text('Grant exact alarm permission'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.lg),
          OutlinedButton.icon(
            onPressed: () {
              final showcase = ShowcaseView.getNamed(TutorialKeys.scope);
              context.read<AppShellViewModel>().setIndex(0);
              context.pop();
              Future<void>.delayed(const Duration(milliseconds: 350), () {
                showcase.startShowCase(TutorialKeys.appTourSteps);
              });
            },
            icon: const Icon(Icons.help_outline_rounded),
            label: const Text('Replay the app tour'),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final ThemeMode mode;
  final ThemeMode current;
  final ValueChanged<ThemeMode> onSelect;

  const _ThemeOption({
    required this.label,
    required this.mode,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RadioListTile<ThemeMode>(
      value: mode,
      groupValue: current,
      onChanged: (value) {
        if (value != null) onSelect(value);
      },
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}
