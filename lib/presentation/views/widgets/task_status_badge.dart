import 'package:flutter/material.dart';
import 'package:taskie/core/constants/app_colors.dart';
import 'package:taskie/data/models/task.dart';

class TaskStatusBadge extends StatelessWidget {
  final Task task;
  final DateTime now;

  const TaskStatusBadge({super.key, required this.task, required this.now});

  @override
  Widget build(BuildContext context) {
    final expired = task.isExpiredAt(now);
    final color = task.isCompleted
        ? AppColors.success
        : expired
        ? AppColors.error
        : AppColors.priorityMedium;
    final label = task.isCompleted
        ? 'Completed'
        : expired
        ? 'Expired'
        : 'Pending';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            task.isCompleted
                ? Icons.check_circle_outline_rounded
                : expired
                ? Icons.timer_off_outlined
                : Icons.schedule_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
