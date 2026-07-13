import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskie/data/models/task.dart';
import 'package:taskie/presentation/viewmodels/add_taskviemodel.dart';
import 'package:taskie/presentation/viewmodels/category_view_model.dart';
import 'package:taskie/presentation/viewmodels/task_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_utils.dart';

// ── Entry point — call this from any widget ───────────────────
void showAddTaskSheet(BuildContext context, {Task? existingTask}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    // Provide AddTaskViewModel locally — it lives only while
    // the sheet is open and is disposed when it closes.
    builder: (_) => ChangeNotifierProvider(
      create: (_) => AddTaskViewModel(existingTask: existingTask),
      child: const _AddTaskSheet(),
    ),
  );
}

// ── The sheet widget ──────────────────────────────────────────
class _AddTaskSheet extends StatelessWidget {
  const _AddTaskSheet();

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final formVM = context.watch<AddTaskViewModel>();
    final catVM  = context.watch<CategoryViewModel>();

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
          AppSizes.pagePadding,
          AppSizes.md,
          AppSizes.pagePadding,
          AppSizes.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Drag handle ──────────────────────────────
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
              formVM.isEditing ? AppStrings.editTask : AppStrings.addTask,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Title field ──────────────────────────────
            TextField(
              controller: formVM.titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'What needs to be done?',
              ),
              onSubmitted: (_) => _save(context, formVM),
            ),
            const SizedBox(height: AppSizes.sm),

            // ── Toggle description ───────────────────────
            TextButton.icon(
              onPressed: formVM.toggleDescription,
              icon: Icon(
                formVM.showDescription
                    ? Icons.remove_circle_outline_rounded
                    : Icons.add_circle_outline_rounded,
                size: 16,
              ),
              label: Text(
                formVM.showDescription
                    ? 'Remove note'
                    : 'Add a note',
                style: const TextStyle(fontSize: 13),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),

            if (formVM.showDescription) ...[
              const SizedBox(height: AppSizes.sm),
              TextField(
                controller: formVM.descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Add a note...',
                ),
              ),
            ],

            const SizedBox(height: AppSizes.lg),

            // ── Priority ─────────────────────────────────
            _SectionLabel(label: 'Priority'),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: Priority.values
                  .map((p) => _PriorityChip(priority: p, formVM: formVM))
                  .toList(),
            ),

            const SizedBox(height: AppSizes.lg),

            // ── Category ─────────────────────────────────
            _SectionLabel(label: 'Category'),
            const SizedBox(height: AppSizes.sm),
            _CategoryDropdown(formVM: formVM, catVM: catVM),

            const SizedBox(height: AppSizes.lg),

            // ── Due date ──────────────────────────────────
            _SectionLabel(label: 'Due date'),
            const SizedBox(height: AppSizes.sm),
            _DueDatePicker(formVM: formVM),

            const SizedBox(height: AppSizes.xl),

            // ── Save button ───────────────────────────────
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

  void _save(BuildContext context, AddTaskViewModel formVM) {
  final taskVM = context.read<TaskViewModel>();
  final desc   = formVM.descriptionController.text.trim();

  if (formVM.isEditing) {
    // Mutate the existing task object and save
    final updated = formVM.existingTask!
      ..title       = formVM.titleController.text.trim()
      ..description = desc.isEmpty ? null : desc
      ..priority    = formVM.priority
      ..categoryId  = formVM.categoryId ?? 0
      ..dueDate     = formVM.dueDate;

    taskVM.updateTask(updated);
  } else {
    taskVM.addTask(
      title:       formVM.titleController.text.trim(),
      description: desc.isEmpty ? null : desc,
      priority:    formVM.priority,
      categoryId:  formVM.categoryId ?? 0,
      dueDate:     formVM.dueDate,
    );
  }

  Navigator.pop(context);
  }
}

// ── Small private widgets used only in this file ──────────────

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

class _PriorityChip extends StatelessWidget {
  final Priority priority;
  final AddTaskViewModel formVM;

  const _PriorityChip({required this.priority, required this.formVM});

  @override
  Widget build(BuildContext context) {
    final isSelected = formVM.priority == priority;
    final color      = Color(priority.colorValue);

    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.sm),
      child: ChoiceChip(
        label: Text(priority.label),
        selected: isSelected,
        onSelected: (_) => formVM.setPriority(priority),
        selectedColor: color.withOpacity(0.15),
        labelStyle: TextStyle(
          color: isSelected ? color : null,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 13,
        ),
        side: BorderSide(
          color: isSelected ? color : Theme.of(context).colorScheme.outline,
        ),
        showCheckmark: false,
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final AddTaskViewModel formVM;
  final CategoryViewModel catVM;

  const _CategoryDropdown({required this.formVM, required this.catVM});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      initialValue: formVM.categoryId,
      decoration: const InputDecoration(hintText: 'No category'),
      items: [
        const DropdownMenuItem(value: null, child: Text('No category')),
        ...catVM.categories.map(
          (cat) => DropdownMenuItem(
            value: cat.id,
            child: Text(cat.name),
          ),
        ),
      ],
      onChanged: formVM.setCategoryId,
    );
  }
}

class _DueDatePicker extends StatelessWidget {
  final AddTaskViewModel formVM;
  const _DueDatePicker({required this.formVM});

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final hasDue   = formVM.dueDate != null;

    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: formVM.dueDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (picked != null) formVM.setDueDate(picked);
      },
      icon: Icon(
        Icons.calendar_today_rounded,
        size: 16,
        color: hasDue
            ? AppColors.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(
        hasDue
            ? DateHelper.format(formVM.dueDate!)
            : 'Pick a date',
        style: TextStyle(
          color: hasDue
              ? AppColors.primary
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: hasDue ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: hasDue
              ? AppColors.primary
              : theme.colorScheme.outline,
        ),
      ),
    );
  }
}