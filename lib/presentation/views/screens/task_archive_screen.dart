import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskie/core/constants/app_sizes.dart';
import 'package:taskie/core/utils/date_utils.dart';
import 'package:taskie/presentation/viewmodels/task_view_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_card.dart';

enum _ArchiveStatus { all, completed, incomplete }

class TaskArchiveScreen extends StatefulWidget {
  const TaskArchiveScreen({super.key});

  @override
  State<TaskArchiveScreen> createState() => _TaskArchiveScreenState();
}

class _TaskArchiveScreenState extends State<TaskArchiveScreen> {
  DateTime? _selectedDate;
  _ArchiveStatus _status = _ArchiveStatus.all;

  @override
  Widget build(BuildContext context) {
    final taskVM = context.watch<TaskViewModel>();
    final theme = Theme.of(context);
    final archive = taskVM.archivedTasksByDate;
    final groups = archive.entries
        .where((entry) => _selectedDate == null || entry.key == _selectedDate)
        .map(
          (entry) => MapEntry(
            entry.key,
            entry.value.where((task) {
              return switch (_status) {
                _ArchiveStatus.all => true,
                _ArchiveStatus.completed => task.isCompleted,
                _ArchiveStatus.incomplete => !task.isCompleted,
              };
            }).toList(),
          ),
        )
        .where((entry) => entry.value.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Archive')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                AppSizes.sm,
                AppSizes.pagePadding,
                AppSizes.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Previous days, kept with their completion status.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Wrap(
                    spacing: AppSizes.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: archive.isEmpty
                            ? null
                            : () async {
                                final dates = archive.keys.toList();
                                final yesterday = DateTime(
                                  taskVM.now.year,
                                  taskVM.now.month,
                                  taskVM.now.day - 1,
                                );
                                var initial = _selectedDate ?? dates.first;
                                if (initial.isBefore(dates.last)) {
                                  initial = dates.last;
                                }
                                if (initial.isAfter(yesterday)) {
                                  initial = yesterday;
                                }
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: initial,
                                  firstDate: dates.last,
                                  lastDate: yesterday,
                                  helpText: 'Find a previous day',
                                );
                                if (picked != null && mounted) {
                                  setState(() => _selectedDate = picked);
                                }
                              },
                        icon: const Icon(
                          Icons.calendar_month_outlined,
                          size: 18,
                        ),
                        label: Text(
                          _selectedDate == null
                              ? 'All dates'
                              : DateHelper.fullDate(_selectedDate!),
                        ),
                      ),
                      if (_selectedDate != null)
                        TextButton(
                          onPressed: () => setState(() => _selectedDate = null),
                          child: const Text('Clear date'),
                        ),
                    ],
                  ),
                  Wrap(
                    spacing: AppSizes.sm,
                    children: _ArchiveStatus.values
                        .map(
                          (status) => ChoiceChip(
                            label: Text(switch (status) {
                              _ArchiveStatus.all => 'All tasks',
                              _ArchiveStatus.completed => 'Completed',
                              _ArchiveStatus.incomplete => 'Not completed',
                            }),
                            selected: _status == status,
                            onSelected: (_) => setState(() => _status = status),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: groups.isEmpty
                  ? EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: archive.isEmpty
                          ? 'No previous tasks yet'
                          : 'No tasks found',
                      subtitle: archive.isEmpty
                          ? 'Tasks move here when their day ends.'
                          : 'Try another date or completion filter.',
                    )
                  : CustomScrollView(
                      slivers: [
                        for (final group in groups) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSizes.pagePadding,
                                AppSizes.md,
                                AppSizes.pagePadding,
                                AppSizes.sm,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateHelper.fullDate(group.key),
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${group.value.where((t) => t.isCompleted).length} completed'
                                    ' · ${group.value.where((t) => !t.isCompleted).length} not completed',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverList.builder(
                            itemCount: group.value.length,
                            itemBuilder: (_, index) => TaskCard(
                              key: ValueKey(group.value[index].id),
                              task: group.value[index],
                            ),
                          ),
                        ],
                        const SliverToBoxAdapter(
                          child: SizedBox(height: AppSizes.xl),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
