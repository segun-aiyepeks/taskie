import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:taskie/core/utils/tutorial_keys.dart';
import 'package:taskie/presentation/viewmodels/category_view_model.dart';
import 'package:taskie/presentation/viewmodels/task_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../viewmodels/add_category_viewmodel.dart';
import '../widgets/add_category_sheet.dart';
import '../widgets/empty_state.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final catVM  = context.watch<CategoryViewModel>();
    final taskVM = context.watch<TaskViewModel>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding, AppSizes.lg,
                AppSizes.pagePadding, AppSizes.md,
              ),
              child: Text(
                'Categories',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),

            // List
            Expanded(
              child: Showcase(
                key: TutorialKeys.categoriesList,
                scope: TutorialKeys.scope,
                title: 'Organize with categories',
                description:
                    'Categories group related tasks and show how many tasks '
                    'belong to each one. Swipe a category to remove it.',
                child: catVM.categories.isEmpty
                    ? const EmptyState(
                        title: 'No categories yet',
                        subtitle: 'Tap + to create your first category.',
                        icon: Icons.folder_outlined,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.pagePadding,
                        ),
                        itemCount: catVM.categories.length,
                        separatorBuilder: (_, _) =>
                            Divider(color: theme.colorScheme.outlineVariant),
                        itemBuilder: (context, i) {
                          final cat = catVM.categories[i];
                          final color = catVM.getColorForCategory(cat.id);
                          final count = taskVM.allTask
                              .where((t) => t.categoryId == cat.id)
                              .length;
                          final iconData =
                              AddCategoryViewModel.icons[cat.iconName] ??
                                  Icons.folder_outlined;

                          return Dismissible(
                            key: ValueKey(cat.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => catVM.deleteCategory(cat.id),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(
                                right: AppSizes.lg,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusMd),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.error,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: AppSizes.sm,
                              ),
                              leading: Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(AppSizes.radiusMd),
                                ),
                                child: Icon(iconData, color: color, size: 22),
                              ),
                              title: Text(
                                cat.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius:
                                      BorderRadius.circular(AppSizes.radiusFull),
                                ),
                                child: Text(
                                  '$count ${count == 1 ? "task" : "tasks"}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Showcase(
        key: TutorialKeys.addCategory,
        scope: TutorialKeys.scope,
        title: 'Create your own category',
        description:
            'Tap + to choose a name, color and icon. Then assign the '
            'category to tasks and filter the task list by it.',
        child: FloatingActionButton(
          onPressed: () => showAddCategorySheet(context),
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}
