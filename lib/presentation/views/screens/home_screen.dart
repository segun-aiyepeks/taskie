import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:taskie/presentation/viewmodels/category_view_model.dart';
import 'package:taskie/presentation/viewmodels/search_view_model.dart';
import 'package:taskie/presentation/viewmodels/settings_view_model.dart';
import 'package:taskie/presentation/viewmodels/task_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/tutorial_keys.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchViewModel(),
      child: const _HomeScreenContent(),
    );
  }
}

// ── StatefulWidget so initState can trigger the tutorial ─────────
class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settingsVM = context.read<SettingsViewModel>();
      if (!settingsVM.hasSeenTutorial) {
        ShowcaseView.getNamed(
          TutorialKeys.scope,
        ).startShowCase(TutorialKeys.appTourSteps);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskVM = context.watch<TaskViewModel>();
    final catVM = context.watch<CategoryViewModel>();
    final searchVM = context.watch<SearchViewModel>();
    final taskGroups = taskVM.filteredTasksByDate;

    searchVM.onQueryChanged = taskVM.setSearchQuery;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: searchVM.isActivity
                  ? const Padding(
                      key: ValueKey('search'),
                      padding: EdgeInsets.only(top: AppSizes.sm),
                      child: _SearchField(),
                    )
                  : Column(
                      key: const ValueKey('filters'),
                      children: [
                        Showcase(
                          key: TutorialKeys.filterTabs,
                          scope: TutorialKeys.scope,
                          title: 'Find the tasks you need',
                          description:
                              'All shows today and upcoming tasks grouped by date. '
                              'Choose Today to focus on this day. Expired shows '
                              'unfinished tasks from past days, kept in Archive.',
                          child: _FilterTabs(taskVM: taskVM),
                        ),
                        if (catVM.categories.isNotEmpty)
                          _CategoryChips(taskVM: taskVM, catVM: catVM),
                      ],
                    ),
            ),
            const SizedBox(height: AppSizes.sm),
            Expanded(
              child: Showcase(
                key: TutorialKeys.taskList,
                scope: TutorialKeys.scope,
                title: 'Your task list',
                description:
                    'Tap a task to see its details, edit it or add subtasks. '
                    'Use the checkbox to mark it done. Expired means an unfinished '
                    'task was left after its scheduled day ended.',
                child: taskGroups.isEmpty
                    ? EmptyState(
                        title: _emptyTitle(taskVM),
                        subtitle: _emptySub(taskVM),
                      )
                    : CustomScrollView(
                        slivers: [
                          for (final group in taskGroups.entries) ...[
                            SliverToBoxAdapter(
                              child: _TaskDateHeader(
                                date: group.key,
                                now: taskVM.now,
                                count: group.value.length,
                              ),
                            ),
                            SliverList.builder(
                              itemCount: group.value.length,
                              itemBuilder: (_, i) => TaskCard(
                                key: ValueKey(group.value[i].id),
                                task: group.value[i],
                              ),
                            ),
                          ],
                          const SliverToBoxAdapter(
                            child: SizedBox(height: AppSizes.xxl + AppSizes.xl),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Showcase(
        key: TutorialKeys.addTask,
        scope: TutorialKeys.scope,
        title: 'Create a task and reminder',
        description:
            'Add a title, notes, priority and category. Set a due date and '
            'time to get a reminder. Open a task later to manage subtasks.',
        child: FloatingActionButton.extended(
          heroTag: 'add-task',
          onPressed: () => showAddTaskSheet(
            context,
            defaultDueDate: taskVM.activeFilter == TaskFilter.today
                ? DateTime.now()
                : null,
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Task'),
        ),
      ),
    );
  }

  String _emptyTitle(TaskViewModel taskVM) {
    if (taskVM.searchQuery.isNotEmpty) return AppStrings.noResultsTitle;
    return switch (taskVM.activeFilter) {
      TaskFilter.today => 'Nothing due today',
      TaskFilter.pending => 'All caught up!',
      TaskFilter.completed => 'No completed tasks yet',
      TaskFilter.all => 'No current or upcoming tasks',
      TaskFilter.expired => 'No expired tasks',
    };
  }

  String _emptySub(TaskViewModel taskVM) {
    if (taskVM.searchQuery.isNotEmpty) {
      return 'No results for "${taskVM.searchQuery}"';
    }
    return switch (taskVM.activeFilter) {
      TaskFilter.today =>
        'A fresh day. Tap Add Task; previous days are in Archive.',
      TaskFilter.pending => 'Tap Add Task to create your first task.',
      TaskFilter.completed => 'Complete a task and it will show here.',
      TaskFilter.all =>
        'Tap Add Task to plan today or a future date. Previous days are in Archive.',
      TaskFilter.expired =>
        'Unfinished tasks appear here after their scheduled day ends.',
    };
  }
} // ← THE MISSING BRACE THAT CAUSED EVERYTHING

// ── Header ───────────────────────────────────────────────────────
class _TaskDateHeader extends StatelessWidget {
  final DateTime date;
  final DateTime now;
  final int count;

  const _TaskDateHeader({
    required this.date,
    required this.now,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final relativeDay = date == today
        ? 'Today'
        : date == tomorrow
        ? 'Tomorrow'
        : null;
    final dateLabel = DateHelper.fullDate(date);

    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pagePadding,
          AppSizes.md,
          AppSizes.pagePadding,
          AppSizes.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                relativeDay == null ? dateLabel : '$relativeDay · $dateLabel',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: date == today
                      ? AppColors.primary
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Text(
              '$count ${count == 1 ? "task" : "tasks"}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskVM = context.watch<TaskViewModel>();
    final settingsVM = context.watch<SettingsViewModel>();
    final totalToday = taskVM.todayCount;
    final completedToday = taskVM.todayCompletedCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        AppSizes.lg,
        AppSizes.pagePadding,
        AppSizes.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${DateHelper.greeting()}, ${settingsVM.displayName}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Search and profile targets begin the first-run tour.
              Showcase(
                key: TutorialKeys.searchIcon,
                scope: TutorialKeys.scope,
                title: 'Search tasks',
                description:
                    'Tap here to search through all your tasks by '
                    'title or description.',
                child: GestureDetector(
                  onTap: () => context.read<SearchViewModel>().activate(),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: AppSizes.sm,
                      right: AppSizes.md,
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      size: 22,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Showcase(
                key: TutorialKeys.profile,
                scope: TutorialKeys.scope,
                title: 'Your profile and settings',
                description:
                    'Tap your initials to set your name, choose a theme, test '
                    'the alarm ringtone and manage reminder timing.',
                child: GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      settingsVM.initials,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'My Tasks',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Showcase(
                key: TutorialKeys.archive,
                scope: TutorialKeys.scope,
                title: 'Look back at previous days',
                description:
                    'Tasks move to Archive when their day ends. Browse by date '
                    'to see what was completed and what expired.',
                child: TextButton.icon(
                  onPressed: () => context.push('/archive'),
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: Text(
                    taskVM.archivedCount == 0
                        ? 'Archive'
                        : 'Archive (${taskVM.archivedCount})',
                  ),
                ),
              ),
            ],
          ),
          Text(
            '${DateHelper.fullDate(taskVM.now)} · $completedToday/$totalToday done today',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (totalToday > 0) ...[
            const SizedBox(height: AppSizes.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                value: completedToday / totalToday,
                minHeight: 5,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  completedToday == totalToday
                      ? AppColors.success
                      : AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Search field ─────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchVM = context.watch<SearchViewModel>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: searchVM.controller,
                      focusNode: searchVM.focusNode,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: AppStrings.searchHint,
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (searchVM.hasQuery)
                    GestureDetector(
                      onTap: searchVM.clearText,
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          GestureDetector(
            onTap: searchVM.deactivate,
            child: const Text(
              AppStrings.cancel,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter tabs ──────────────────────────────────────────────────
class _FilterTabs extends StatelessWidget {
  final TaskViewModel taskVM;
  const _FilterTabs({required this.taskVM});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
      child: Row(
        children: TaskFilter.values
            .map(
              (f) => _FilterChip(
                filter: f,
                isActive: taskVM.activeFilter == f,
                onTap: () => taskVM.setFilter(f),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final TaskFilter filter;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.filter,
    required this.isActive,
    required this.onTap,
  });

  String get _label => switch (filter) {
    TaskFilter.all => 'All',
    TaskFilter.today => 'Today',
    TaskFilter.pending => 'Pending',
    TaskFilter.completed => 'Done',
    TaskFilter.expired => 'Expired',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.sm),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          child: Text(
            _label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Category chips ───────────────────────────────────────────────
class _CategoryChips extends StatelessWidget {
  final TaskViewModel taskVM;
  final CategoryViewModel catVM;

  const _CategoryChips({required this.taskVM, required this.catVM});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        AppSizes.sm,
        AppSizes.pagePadding,
        0,
      ),
      child: Row(
        children: [
          _CatChip(
            label: 'All',
            color: AppColors.primary,
            isActive: taskVM.filterCategoryId == null,
            onTap: () => taskVM.setFilterCategory(null),
          ),
          ...catVM.categories.map(
            (cat) => _CatChip(
              label: cat.name,
              color: catVM.getColorForCategory(cat.id),
              isActive: taskVM.filterCategoryId == cat.id,
              onTap: () => taskVM.setFilterCategory(
                taskVM.filterCategoryId == cat.id ? null : cat.id,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _CatChip({
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: isActive ? color : theme.colorScheme.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? color : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
