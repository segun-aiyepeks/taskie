import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:taskie/core/constants/app_colors.dart';
import 'package:taskie/core/constants/app_sizes.dart';
import 'package:taskie/core/utils/date_utils.dart';
import 'package:taskie/data/models/task.dart';
import 'package:taskie/presentation/viewmodels/category_view_model.dart';
import 'package:taskie/presentation/viewmodels/task_view_model.dart';
import 'package:taskie/presentation/views/widgets/priority_badge.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // context.read - we only need to call methods, not rebuild on change
    final taskVM = context.read<TaskViewModel>();
    // context.watch - we want to rebuild when categories change
    final catVM = context.watch<CategoryViewModel>();
    final cat = catVM.getCategorybyId(task.categoryId);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.pagePadding, vertical: 4),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: InkWell(
          onTap: () {
            context.push('/task/${task.id}');
          },
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppSizes.radiusMd), border: Border.all(color: theme.colorScheme.outlineVariant)),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => taskVM.toggleTaskCompletion(task.id),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 180),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: task.isCompleted? AppColors.primary: Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: task.isCompleted? AppColors.primary: theme.colorScheme.outline,
                        width: 1.5
                      )
                    ),
                    child: task.isCompleted? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ): null
                  ),
                ),
                SizedBox(width: 16.0),
                //Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: task.isCompleted? theme.colorScheme.onSurfaceVariant: theme.colorScheme.onSurface,
                          decoration: task.isCompleted?TextDecoration.lineThrough: null,
                          decorationColor: theme.colorScheme.onSurfaceVariant
                        ),
                      ),

                      //Metadata: dueDate . category
                      if(task.dueDate != null || cat != null)...[
                        SizedBox(height: 8.0),
                        Row(
                          children: [
                            if(task.dueDate != null)... [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: task.isOverdue? AppColors.error: theme.colorScheme.onSurfaceVariant
                              ),
                              SizedBox(width: 4.0),
                              Text(
                                DateHelper.format(task.dueDate!),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: task.isOverdue? AppColors.error: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: task.isOverdue?FontWeight.w600: FontWeight.w400
                                ),
                              )
                            ],
                            if(task.dueDate != null && cat != null)
                            Padding(
                              padding: EdgeInsetsGeometry.symmetric(horizontal: 8),
                              child: Container(
                                width: 4.0, height: 4.0,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  shape: BoxShape.circle
                                ),
                              ), 
                            ),
                            if(cat != null)...[
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  color: catVM.getColorForCategory(task.categoryId),
                                  shape: BoxShape.circle
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                cat.name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                ),
                              )
                            ]
                          ],
                        )
                      ]
                    ],
                  )),
                  const SizedBox(width: 10),
                  PriorityBadge(priority: task.priority)
              ],
            ),
          ),
        ),
      ),
    );
  }
}