import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:taskie/core/utils/tutorial_keys.dart';
import 'package:taskie/presentation/viewmodels/timetable_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../widgets/add_entry_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/timetable_entry_card.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timetableVM = context.watch<TimetableViewModel>();

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                AppSizes.lg,
                AppSizes.pagePadding,
                AppSizes.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timetableVM.entryCount == 0
                        ? timetableVM.selectedDayName
                        : '${timetableVM.selectedDayName} · '
                              '${timetableVM.entryCount} '
                              '${timetableVM.entryCount == 1 ? "entry" : "entries"}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // ── Day selector ─────────────────────────────
            Showcase(
              key: TutorialKeys.scheduleDays,
              scope: TutorialKeys.scope,
              title: 'Choose a day',
              description:
                  'Tap a day to view its schedule. Entries can repeat on '
                  'multiple days of the week.',
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.pagePadding,
                ),
                child: Row(
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    final isSelected = timetableVM.selectedDay == day;
                    final isToday = day == DateTime.now().weekday;

                    return Padding(
                      padding: const EdgeInsets.only(right: AppSizes.sm),
                      child: GestureDetector(
                        onTap: () => timetableVM.selectDay(day),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusFull,
                            ),
                            border: isToday && !isSelected
                                ? Border.all(color: AppColors.primary)
                                : null,
                          ),
                          child: Column(
                            children: [
                              Text(
                                TimetableViewModel.dayShort[i],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : isToday
                                      ? AppColors.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(height: 3),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: AppSizes.md),

            // ── Entry list ───────────────────────────────
            Expanded(
              child: Showcase(
                key: TutorialKeys.scheduleList,
                scope: TutorialKeys.scope,
                title: 'Your weekly schedule',
                description:
                    'Entries show their time and repeat days. Tap one to edit '
                    'it, or swipe it away to delete it.',
                child: timetableVM.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : timetableVM.entries.isEmpty
                    ? EmptyState(
                        icon: Icons.calendar_today_outlined,
                        title:
                            'No entries for '
                            '${timetableVM.selectedDayName}',
                        subtitle:
                            'Tap Add Schedule to create a recurring schedule block.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          top: AppSizes.xs,
                          bottom: AppSizes.xxl + AppSizes.xl,
                        ),
                        itemCount: timetableVM.entries.length,
                        itemBuilder: (_, i) {
                          final entry = timetableVM.entries[i];
                          return TimetableEntryCard(
                            entry: entry,
                            onDelete: () => timetableVM.deleteEntry(entry.id),
                            onEdit: () => showAddEntrySheet(
                              context,
                              initialDay: timetableVM.selectedDay,
                              existingEntry: entry,
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
        key: TutorialKeys.addSchedule,
        scope: TutorialKeys.scope,
        title: 'Add a schedule and alarm',
        description:
            'Choose the repeat days and start/end times. Leave Reminder on '
            'to ring at the start time on each selected day.',
        child: FloatingActionButton.extended(
          heroTag: 'add-schedule',
          onPressed: () =>
              showAddEntrySheet(context, initialDay: timetableVM.selectedDay),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Schedule'),
        ),
      ),
    );
  }
}
