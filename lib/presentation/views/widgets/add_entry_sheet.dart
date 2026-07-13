import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskie/presentation/viewmodels/add_entry_view_model.dart';
import 'package:taskie/presentation/viewmodels/timetable_view_model.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/timetable_entry.dart';

void showAddEntrySheet(BuildContext context, {required int initialDay}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider(
      create: (_) => AddEntryViewModel(initialDay: initialDay),
      child: const _AddEntrySheet(),
    ),
  );
}

class _AddEntrySheet extends StatelessWidget {
  const _AddEntrySheet();

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final formVM = context.watch<AddEntryViewModel>();

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
              'New schedule entry',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Title
            TextField(
              controller: formVM.titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Entry title'),
            ),
            const SizedBox(height: AppSizes.sm),

            // Note toggle
            TextButton.icon(
              onPressed: formVM.toggleNote,
              icon: Icon(
                formVM.showNote
                    ? Icons.remove_circle_outline_rounded
                    : Icons.add_circle_outline_rounded,
                size: 16,
              ),
              label: Text(
                formVM.showNote ? 'Remove note' : 'Add a note',
                style: const TextStyle(fontSize: 13),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            if (formVM.showNote) ...[
              const SizedBox(height: AppSizes.sm),
              TextField(
                controller: formVM.noteController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Optional note...'),
              ),
            ],

            const SizedBox(height: AppSizes.lg),

            // Day selector
            _SectionLabel(label: 'Day'),
            const SizedBox(height: AppSizes.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(7, (i) {
                  final day       = i + 1;
                  final isSelected = formVM.selectedDay == day;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(AddEntryViewModel.dayShort[i]),
                      selected: isSelected,
                      onSelected: (_) => formVM.setDay(day),
                      selectedColor: const Color(0xFF4F67F8),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                      showCheckmark: false,
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // Time pickers
            _SectionLabel(label: 'Time'),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: 'Start',
                    minutes: formVM.startMinutes,
                    formatted: formVM.formatMinutes(formVM.startMinutes),
                    onPick: (ctx) async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: formVM.minutesToTimeOfDay(
                          formVM.startMinutes,
                        ),
                      );
                      if (picked != null) {
                        formVM.setStartMinutes(
                          formVM.timeOfDayToMinutes(picked),
                        );
                      }
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.sm),
                  child: Text('→'),
                ),
                Expanded(
                  child: _TimePicker(
                    label: 'End',
                    minutes: formVM.endMinutes,
                    formatted: formVM.formatMinutes(formVM.endMinutes),
                    onPick: (ctx) async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: formVM.minutesToTimeOfDay(
                          formVM.endMinutes,
                        ),
                      );
                      if (picked != null) {
                        formVM.setEndMinutes(
                          formVM.timeOfDayToMinutes(picked),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),

            // End-before-start validation
            if (formVM.endMinutes <= formVM.startMinutes) ...[
              const SizedBox(height: AppSizes.sm),
              Text(
                'End time must be after start time.',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: AppSizes.lg),

            // Colour picker
            _SectionLabel(label: 'Colour'),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: AddEntryViewModel.palletes.map((hex) {
                final color      = _hexToColor(hex);
                final isSelected = formVM.colorHex == hex;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => formVM.setColor(hex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 34, height: 34,
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
                              size: 16, color: Colors.white)
                          : null,
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
                child: const Text('Save entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save(BuildContext context, AddEntryViewModel formVM) {
    final entry = TimetableEntry()
      ..title        = formVM.titleController.text.trim()
      ..note         = formVM.noteController.text.trim().isEmpty
          ? null
          : formVM.noteController.text.trim()
      ..dayOfTheWeek    = formVM.selectedDay
      ..startMinutes = formVM.startMinutes
      ..endMinutes   = formVM.endMinutes
      ..colorHex     = formVM.colorHex
      ..createdAt    = DateTime.now();

    context.read<TimetableViewModel>().addEntry(entry);
    Navigator.pop(context);
  }

  static Color _hexToColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }
}

// ── Private helpers ────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
}

class _TimePicker extends StatelessWidget {
  final String label;
  final int    minutes;
  final String formatted;
  final Future<void> Function(BuildContext) onPick;

  const _TimePicker({
    required this.label,
    required this.minutes,
    required this.formatted,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onPick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: 14,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatted,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}