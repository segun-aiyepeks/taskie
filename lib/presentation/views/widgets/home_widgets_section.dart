import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:taskie/core/constants/app_colors.dart';
import 'package:taskie/core/constants/app_sizes.dart';
import 'package:taskie/core/services/home_widget_service.dart';

class HomeWidgetsSection extends StatefulWidget {
  const HomeWidgetsSection({super.key});

  @override
  State<HomeWidgetsSection> createState() => _HomeWidgetsSectionState();
}

class _HomeWidgetsSectionState extends State<HomeWidgetsSection> {
  HomeWidgetKind? _adding;

  @override
  Widget build(BuildContext context) {
    final widgets = context.watch<HomeWidgetService>();
    if (!widgets.isSupported) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Home screen widgets', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSizes.sm),
        Text(
          'See what is next without opening Taskie. Choose either widget to add it to your phone’s home screen.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSizes.md),
        for (final kind in HomeWidgetKind.values) ...[
          _WidgetOption(
            kind: kind,
            count: kind == HomeWidgetKind.task
                ? widgets.taskWidgetCount
                : widgets.scheduleWidgetCount,
            busy: _adding == kind,
            buttonLabel: widgets.pinSupported
                ? 'Add to home screen'
                : 'How to add',
            onAdd: widgets.isReady && _adding == null ? () => _add(kind) : null,
          ),
          const SizedBox(height: AppSizes.sm),
        ],
        if (widgets.syncError != null)
          Text(
            widgets.syncError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        if (!widgets.isReady && widgets.syncError == null)
          const Text('Loading your tasks and schedule…'),
        const SizedBox(height: AppSizes.sm),
        Text(
          'To remove a widget, touch and hold it on your home screen, then choose Remove.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _add(HomeWidgetKind kind) async {
    final widgets = context.read<HomeWidgetService>();
    setState(() => _adding = kind);
    try {
      final requested = await widgets.requestPin(kind);
      if (!mounted) return;
      if (requested) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Confirm the widget placement on your home screen.'),
          ),
        );
      } else if (widgets.syncError != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(widgets.syncError!)));
      } else {
        _showManualSteps(kind);
      }
    } on PlatformException catch (_) {
      if (mounted) _showManualSteps(kind);
    } on MissingPluginException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Install the updated Android app to use home screen widgets.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = null);
    }
  }

  void _showManualSteps(HomeWidgetKind kind) {
    final name = kind == HomeWidgetKind.task
        ? 'Taskie: Next task'
        : 'Taskie: Next schedule';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a Taskie widget'),
        content: Text(
          '1. Touch and hold an empty space on your home screen.\n\n'
          '2. Tap Widgets and find Taskie.\n\n'
          '3. Touch and hold “$name”, then place it on your home screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _WidgetOption extends StatelessWidget {
  final HomeWidgetKind kind;
  final int count;
  final bool busy;
  final String buttonLabel;
  final VoidCallback? onAdd;

  const _WidgetOption({
    required this.kind,
    required this.count,
    required this.busy,
    required this.buttonLabel,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final task = kind == HomeWidgetKind.task;
    final theme = Theme.of(context);
    final color = task ? AppColors.primary : AppColors.success;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                task ? Icons.task_alt_rounded : Icons.calendar_month_rounded,
                color: color,
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  task ? 'Next task' : 'Next schedule',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            task
                ? 'Your next unfinished task, ordered by its reminder time.'
                : 'The next start time in your weekly schedule, including repeat days.',
            style: theme.textTheme.bodySmall,
          ),
          if (count > 0) ...[
            const SizedBox(height: AppSizes.sm),
            Text(
              '$count on your home screen',
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
          const SizedBox(height: AppSizes.sm),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_to_home_screen_rounded, size: 18),
            label: Text(busy ? 'Opening…' : buttonLabel),
          ),
        ],
      ),
    );
  }
}
