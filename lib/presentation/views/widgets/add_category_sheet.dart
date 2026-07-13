import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskie/presentation/viewmodels/category_view_model.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/category.dart';
import '../../viewmodels/add_category_viewmodel.dart';

void showAddCategorySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider(
      create: (_) => AddCategoryViewModel(),
      child: const _AddCategorySheet(),
    ),
  );
}

class _AddCategorySheet extends StatelessWidget {
  const _AddCategorySheet();

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final formVM = context.watch<AddCategoryViewModel>();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pagePadding, AppSizes.md,
          AppSizes.pagePadding, AppSizes.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: AppSizes.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              'New category',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Name field
            TextField(
              controller: formVM.nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Category name'),
            ),

            const SizedBox(height: AppSizes.lg),

            // Colour picker
            Text(
              'Colour',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: AppSizes.sm,
              children: AddCategoryViewModel.palette.map((color) {
                final isSelected = formVM.selectedColor == color;
                return GestureDetector(
                  onTap: () => formVM.setColor(color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.onSurface,
                              width: 3,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            size: 18, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSizes.lg),

            // Icon picker
            Text(
              'Icon',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: AppSizes.sm,
              children: AddCategoryViewModel.icons.entries.map((entry) {
                final isSelected = formVM.selectedIcon == entry.key;
                return GestureDetector(
                  onTap: () => formVM.setIcon(entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? formVM.selectedColor.withOpacity(0.15)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      border: isSelected
                          ? Border.all(color: formVM.selectedColor, width: 1.5)
                          : null,
                    ),
                    child: Icon(
                      entry.value,
                      size: 22,
                      color: isSelected
                          ? formVM.selectedColor
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSizes.xl),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: formVM.canSave
                    ? () => _save(context, formVM)
                    : null,
                child: const Text(AppStrings.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save(BuildContext context, AddCategoryViewModel formVM) {
    final category = Category()
      ..name     = formVM.nameController.text.trim()
      ..hexColor = formVM.colorHex
      ..iconName = formVM.selectedIcon;

    context.read<CategoryViewModel>().addCategory(category);
    Navigator.pop(context);
  }
}