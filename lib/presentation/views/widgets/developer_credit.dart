import 'package:flutter/material.dart';
import 'package:taskie/core/constants/app_strings.dart';

class DeveloperCredit extends StatelessWidget {
  const DeveloperCredit({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      AppStrings.developerCredit,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
        fontSize: 11.0,
        letterSpacing: 0.5
      ),
    );
  }
}