import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:taskie/presentation/viewmodels/edit_name_view_model.dart';
import 'package:taskie/presentation/viewmodels/settings_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final settingsVM  = context.watch<SettingsViewModel>();
    final editVM      = context.watch<EditNameViewModel>();

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
                  decoration:
                      const InputDecoration(hintText: 'Enter your name'),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              IconButton.filled(
                onPressed: () {
                  settingsVM.setUserName(editVM.nameController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name updated')),
                  );
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
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String     label;
  final ThemeMode  mode;
  final ThemeMode  current;
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