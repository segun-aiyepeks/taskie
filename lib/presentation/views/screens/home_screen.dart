import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:taskie/presentation/viewmodels/category_view_model.dart';
import 'package:taskie/presentation/viewmodels/search_view_model.dart';
import 'package:taskie/presentation/viewmodels/settings_view_model.dart';
import 'package:taskie/presentation/viewmodels/task_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_utils.dart';
import '../../viewmodels/stats_viewmodel.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_card.dart';

// ── Entry point ────────────────────────────────────────────────
// HomeScreen's only job is to create SearchViewModel and scope it
// to this tab. Everything else lives in _HomeScreenView below.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchViewModel(),
      child: const _HomeScreenView(),
    );
  }
}

// ── Main view — sits below the SearchViewModel provider ────────
class _HomeScreenView extends StatelessWidget {
  const _HomeScreenView();

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final taskVM   = context.watch<TaskViewModel>();
    final statsVM  = context.watch<StatsViewmodel>();
    final catVM    = context.watch<CategoryViewModel>();
    final searchVM = context.watch<SearchViewModel>();

    // Wire search input directly to the filtering logic in TaskViewModel.
    // Reassigning every build is cheap — it's just a function reference.
    searchVM.onQueryChanged = taskVM.setSearchQuery;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header (greeting + search icon + avatar) ───
            const _Header(),

            // ── Search field OR filter tabs — never both ───
            // AnimatedSwitcher swaps between the two based on
            // whether search mode is active. The key: value
            // change is what triggers the cross-fade animation.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: searchVM.isActivity
                  ? const Padding(
                      key: ValueKey('search'),
                      padding: EdgeInsets.only(top: AppSizes.sm),
                      child: _SearchField(),      // ← used here
                    )
                  : Column(
                      key: const ValueKey('filters'),
                      children: [
                        _FilterTabs(taskVM: taskVM),
                        if (catVM.categories.isNotEmpty)
                          _CategoryChips(taskVM: taskVM, catVM: catVM),
                      ],
                    ),
            ),

            const SizedBox(height: AppSizes.sm),

            // ── Task list ──────────────────────────────────
            Expanded(
              child: taskVM.filteredTasks.isEmpty
                  ? EmptyState(
                      title: _emptyTitle(taskVM),
                      subtitle: _emptySub(taskVM),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        bottom: AppSizes.xxl + AppSizes.xl,
                      ),
                      itemCount: taskVM.filteredTasks.length,
                      itemBuilder: (_, i) =>
                          TaskCard(task: taskVM.filteredTasks[i]),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddTaskSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  String _emptyTitle(TaskViewModel taskVM) {
    if (taskVM.searchQuery.isNotEmpty) return AppStrings.noResultsTitle;
    return switch (taskVM.activeFilter) {
      TaskFilter.today     => 'Nothing due today',
      TaskFilter.pending   => 'All caught up!',
      TaskFilter.completed => 'No completed tasks yet',
      TaskFilter.all       => 'No tasks yet',
    };
  }

  String _emptySub(TaskViewModel taskVM) {
    if (taskVM.searchQuery.isNotEmpty) {
      return 'No results for "${taskVM.searchQuery}"';
    }
    return switch (taskVM.activeFilter) {
      TaskFilter.today     => 'Add a task and set today as the due date.',
      TaskFilter.pending   => 'Tap + to create your first task.',
      TaskFilter.completed => 'Complete a task and it will show here.',
      TaskFilter.all       => 'Tap + to create your first task.',
    };
  }
}

// ── Header ─────────────────────────────────────────────────────
// Kept as a const-constructable widget so Flutter can skip
// rebuilding it when unrelated state changes. It reads
// SearchViewModel directly — this works because _Header is
// rendered below the ChangeNotifierProvider in HomeScreen.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final statsVM    = context.watch<StatsViewmodel>();
    final settingsVM = context.watch<SettingsViewModel>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pagePadding, AppSizes.lg,
        AppSizes.pagePadding, AppSizes.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Greeting row ─────────────────────────────────
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

              // ── Search icon ────────────────────────────
              // context.read is correct here — we're in a callback/
              // gesture, not subscribing to rebuilds. Using watch
              // here would be wasteful and cause extra rebuilds.
              GestureDetector(
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

              // ── Avatar → Settings ─────────────────────
              GestureDetector(
                onTap: () => context.push('/settings'),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
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
            ],
          ),

          const SizedBox(height: 2),

          // ── Title row ────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'My Tasks',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (statsVM.totalTasks > 0)
                Text(
                  '${statsVM.completedTasks}/${statsVM.totalTasks} done',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),

          // ── Progress bar ──────────────────────────────────
          if (statsVM.totalTasks > 0) ...[
            const SizedBox(height: AppSizes.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                value: statsVM.completionRate,
                minHeight: 5,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  statsVM.completionRate == 1.0
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

// ── Search field ───────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final searchVM = context.watch<SearchViewModel>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
      child: Row(
        children: [

          // ── Pill-shaped input container ───────────────
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
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
                        // These three explicitly override app_theme.dart's
                        // global input decoration — we don't want the filled
                        // background or the border inside this pill container.
                        border: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),

                  // ── Clear button ──────────────────────
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

          // ── Cancel button ─────────────────────────────
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

// ── Filter tabs ────────────────────────────────────────────────
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
            .map((f) => _FilterChip(
                  filter: f,
                  isActive: taskVM.activeFilter == f,
                  onTap: () => taskVM.setFilter(f),
                ))
            .toList(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final TaskFilter   filter;
  final bool         isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.filter,
    required this.isActive,
    required this.onTap,
  });

  String get _label => switch (filter) {
    TaskFilter.all       => 'All',
    TaskFilter.today     => 'Today',
    TaskFilter.pending   => 'Pending',
    TaskFilter.completed => 'Done',
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
                : theme.colorScheme.surfaceVariant,
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

// ── Category filter chips ──────────────────────────────────────
class _CategoryChips extends StatelessWidget {
  final TaskViewModel     taskVM;
  final CategoryViewModel catVM;

  const _CategoryChips({required this.taskVM, required this.catVM});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pagePadding, AppSizes.sm, AppSizes.pagePadding, 0,
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
  final String       label;
  final Color        color;
  final bool         isActive;
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
                ? color.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: isActive
                  ? color
                  : theme.colorScheme.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? color
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}