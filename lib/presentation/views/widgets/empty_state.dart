import 'package:flutter/material.dart';
import 'package:taskie/core/constants/app_sizes.dart';
import 'package:taskie/core/constants/app_strings.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const EmptyState({super.key, this.title = AppStrings.emptyTitle, this.subtitle = AppStrings.emptySub, this.icon = Icons.check_circle_outline_rounded});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSizes.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            SizedBox(height: AppSizes.md,),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSizes.sm),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}