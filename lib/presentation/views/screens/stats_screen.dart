import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:taskie/core/utils/tutorial_keys.dart';
import 'package:taskie/presentation/viewmodels/stats_viewmodel.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final statsVM = context.watch<StatsViewmodel>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding, AppSizes.lg,
            AppSizes.pagePadding, AppSizes.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                'Progress',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: AppSizes.xl),

              // ── Progress ring ──────────────────────────
              Center(
                child: Showcase(
                  key: TutorialKeys.progressRing,
                  scope: TutorialKeys.scope,
                  title: 'Track your progress',
                  description:
                      'The ring shows your completed-task percentage and '
                      'updates as you finish or reopen tasks.',
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 180, height: 180,
                            child: CircularProgressIndicator(
                              value: statsVM.completionRate,
                              strokeWidth: 14,
                              strokeCap: StrokeCap.round,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                statsVM.completionRate >= 1.0
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                '${(statsVM.completionRate * 100).toStringAsFixed(0)}%',
                                style: theme.textTheme.displaySmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'complete',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),
                      Text(
                        _motivationalMessage(statsVM.completionRate),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.xl),

              // ── Summary cards ──────────────────────────
              Text(
                'Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Showcase(
                key: TutorialKeys.progressSummary,
                scope: TutorialKeys.scope,
                title: 'Read your task summary',
                description:
                    'See total, completed, pending and due-today counts. '
                    'When you have tasks, the priority breakdown appears below.',
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSizes.sm,
                    mainAxisSpacing: AppSizes.sm,
                    mainAxisExtent: 112,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, i) {
                    final cards = [
                      _StatCard(
                        label: 'Total',
                        value: statsVM.totalTasks,
                        color: AppColors.primary,
                        icon: Icons.assignment_outlined,
                      ),
                      _StatCard(
                        label: 'Completed',
                        value: statsVM.completedTasks,
                        color: AppColors.success,
                        icon: Icons.check_circle_outlined,
                      ),
                      _StatCard(
                        label: 'Pending',
                        value: statsVM.pendingTasks,
                        color: AppColors.priorityMedium,
                        icon: Icons.pending_outlined,
                      ),
                      _StatCard(
                        label: 'Due Today',
                        value: statsVM.todayTasks,
                        color: AppColors.priorityHigh,
                        icon: Icons.today_outlined,
                      ),
                    ];
                    return cards[i];
                  },
                ),
              ),

              const SizedBox(height: AppSizes.xl),

              // ── Priority breakdown ─────────────────────
              if (statsVM.totalTasks > 0) ...[
                Text(
                  'By priority',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                _PriorityBar(
                  label: 'High',
                  count: statsVM.highPriorityTasks,
                  total: statsVM.totalTasks,
                  color: AppColors.priorityHigh,
                ),
                const SizedBox(height: AppSizes.sm),
                _PriorityBar(
                  label: 'Medium',
                  count: statsVM.mediumPriorityTasks,
                  total: statsVM.totalTasks,
                  color: AppColors.priorityMedium,
                ),
                const SizedBox(height: AppSizes.sm),
                _PriorityBar(
                  label: 'Low',
                  count: statsVM.lowPriorityTasks,
                  total: statsVM.totalTasks,
                  color: AppColors.priorityLow,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _motivationalMessage(double rate) {
    if (rate == 0)   return 'Start ticking tasks off your list 💪';
    if (rate < 0.25) return 'Great start — keep the momentum going!';
    if (rate < 0.5)  return "You're making solid progress.";
    if (rate < 0.75) return 'More than halfway there — finish strong!';
    if (rate < 1.0)  return 'Almost done — one final push!';
    return 'Everything done. Enjoy the moment! 🎉';
  }
}

// ── Private widgets ────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String   label;
  final int      value;
  final Color    color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ← only take the space it needs
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.iconMd, color: color),
          const SizedBox(height: AppSizes.sm),
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith( // slightly smaller than before
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBar extends StatelessWidget {
  final String label;
  final int    count;
  final int    total;
  final Color  color;

  const _PriorityBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = total == 0 ? 0.0 : count / total;

    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        SizedBox(
          width: 24,
          child: Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
