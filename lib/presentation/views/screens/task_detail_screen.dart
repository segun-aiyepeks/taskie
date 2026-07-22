import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:taskie/data/models/subtasks.dart';
import 'package:taskie/presentation/viewmodels/category_view_model.dart';
import 'package:taskie/presentation/viewmodels/task_detail_view_model.dart';
import 'package:taskie/presentation/viewmodels/task_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_utils.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/priority_badge.dart';

class TaskDetailScreen extends StatelessWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    final taskVM = context.watch<TaskViewModel>();
    final task   = taskVM.getTaskbyId(taskId);

    // Task was deleted — go back immediately
    if (task == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme  = Theme.of(context);
    final catVM  = context.watch<CategoryViewModel>();
    final cat    = catVM.getCategorybyId(task.categoryId);
    final detailVM = context.watch<TaskDetailViewModel>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop()
        ),
        actions: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit task',
            onPressed: () => showAddTaskSheet(
              context,
              existingTask: task,
            ),
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete task',
            color: AppColors.error,
            onPressed: () => _confirmDelete(context, taskVM, task.id),
          ),
          const SizedBox(width: AppSizes.sm),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pagePadding,
          AppSizes.sm,
          AppSizes.pagePadding,
          AppSizes.xxl,
        ),
        children: [

          // ── Status + Priority row ──────────────────────
          Row(
            children: [
              PriorityBadge(priority: task.priority, showLabel: true),
              const SizedBox(width: AppSizes.sm),
              _StatusChip(isCompleted: task.isCompleted),
            ],
          ),

          const SizedBox(height: AppSizes.md),

          // ── Title ─────────────────────────────────────
          Text(
            task.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              decoration: task.isCompleted
                  ? TextDecoration.lineThrough
                  : null,
              decorationColor: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          // ── Metadata ───────────────────────────────────
          _MetaRow(
            icon: Icons.access_time_rounded,
            label: task.dueDate != null
                ? DateHelper.format(task.dueDate!)
                : 'No due date',
            color: task.isOverdue
                ? AppColors.error
                : theme.colorScheme.onSurfaceVariant,
          ),

          if (cat != null) ...[
            const SizedBox(height: AppSizes.sm),
            _MetaRow(
              icon: Icons.folder_outlined,
              label: cat.name,
              color: catVM.getColorForCategory(task.categoryId),
            ),
          ],

          // ── Description ────────────────────────────────
          if (task.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSizes.lg),
            _SectionHeader(title: 'Note'),
            const SizedBox(height: AppSizes.sm),
            Text(
              task.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.7,
              ),
            ),
          ],

          const SizedBox(height: AppSizes.lg),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: AppSizes.md),

          // ── Subtasks ───────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionHeader(
                title: task.subtasks.isEmpty
                    ? 'Subtasks'
                    : 'Subtasks  '
                      '${task.completedSubtaskCount}/${task.subtasks.length}',
              ),
              TextButton.icon(
                onPressed: detailVM.showInput
                    ? detailVM.closeInput
                    : detailVM.openInput,
                icon: Icon(
                  detailVM.showInput
                      ? Icons.close_rounded
                      : Icons.add_rounded,
                  size: 16,
                ),
                label: Text(
                  detailVM.showInput ? 'Cancel' : 'Add',
                  style: const TextStyle(fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),

          // Subtask list
          ...task.subtasks.map(
            (subtask) => _SubtaskTile(
              subtask: subtask,
              taskId: task.id,
              taskVM: taskVM,
            ),
          ),

          // Inline add subtask input
          if (detailVM.showInput) ...[
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: detailVM.subtaskController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'New subtask...',
                      isDense: true,
                    ),
                    onSubmitted: (_) =>
                        _saveSubtask(context, taskVM, detailVM, task.id),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                IconButton.filled(
                  onPressed: detailVM.canAdd
                      ? () => _saveSubtask(
                            context,
                            taskVM,
                            detailVM,
                            task.id,
                          )
                      : null,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(40, 40),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSizes.xl),

          // ── Complete / Reopen button ───────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => taskVM.toggleTaskCompletion(task.id),
              icon: Icon(
                task.isCompleted
                    ? Icons.refresh_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18,
              ),
              label: Text(
                task.isCompleted ? 'Reopen task' : 'Mark complete',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: task.isCompleted
                    ? theme.colorScheme.onSurfaceVariant
                    : AppColors.success,
                side: BorderSide(
                  color: task.isCompleted
                      ? theme.colorScheme.outline
                      : AppColors.success,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveSubtask(
    BuildContext context,
    TaskViewModel taskVM,
    TaskDetailViewModel detailVM,
    int taskId,
  ) {
    taskVM.addSubtasks(taskId, detailVM.subtaskController.text);
    detailVM.closeInput();
  }

  void _confirmDelete(
    BuildContext context,
    TaskViewModel taskVM,
    int taskId,
  ) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteConfirmTitle),
        content: const Text(AppStrings.deleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(AppStrings.confirmDelete),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        taskVM.deleteTask(taskId);
        context.go('/');
      }
    });
  }
}

// ── Private widgets ────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final bool isCompleted;
  const _StatusChip({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? AppColors.success : AppColors.priorityMedium;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isCompleted ? 'Completed' : 'Pending',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}

class _SubtaskTile extends StatelessWidget {
  final Subtasks      subtask;
  final int           taskId;
  final TaskViewModel taskVM;

  const _SubtaskTile({
    required this.subtask,
    required this.taskId,
    required this.taskVM,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // Tap anywhere on the row to toggle — not just the checkbox
          onTap: () => taskVM.toggleSubtask(taskId, subtask.subtaskId),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSizes.sm, horizontal: 2,
            ),
            child: Row(
              children: [
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: subtask.isCompleted
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: subtask.isCompleted
                          ? AppColors.primary
                          : theme.colorScheme.outline,
                      width: 1.5,
                    ),
                  ),
                  child: subtask.isCompleted
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),

                // Title
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: (theme.textTheme.bodyMedium ?? const TextStyle())
                        .copyWith(
                      color: subtask.isCompleted
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                      decoration: subtask.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: theme.colorScheme.onSurfaceVariant,
                    ),
                    child: Text(subtask.title),
                  ),
                ),

                // Delete
                GestureDetector(
                  onTap: () => taskVM.deleteSubTask(taskId, subtask.subtaskId),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant
                          .withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}