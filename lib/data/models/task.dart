import 'package:isar/isar.dart';
import 'package:taskie/core/constants/app_enums.dart';
import 'package:taskie/data/models/subtasks.dart';

part 'task.g.dart';

@collection
class Task {
  Id id = Isar.autoIncrement;

  late String title;
  String? description;

  @Enumerated(EnumType.ordinal)
  late Priority priority;

  @Enumerated(EnumType.ordinal)
  TaskStatus status = TaskStatus.pending;

  @Index()
  DateTime createdAt = DateTime.now();

  @Index()
  DateTime? dueDate;

  DateTime? completedAt;

  int categoryId = 0;

  List<Subtasks> subtasks = [];

  bool get isCompleted => status == TaskStatus.completed;
  bool get isPending => status == TaskStatus.pending;

  bool get isDueToday => isScheduledFor(DateTime.now());

  bool get isOverdue => isExpiredAt(DateTime.now());

  int get completedSubtaskCount => subtasks.where((s) => s.isCompleted).length;

  double get subtaskProgress {
    if (subtasks.isEmpty) return 0.0;
    return completedSubtaskCount / subtasks.length;
  }
}

/// Calendar state is calculated from saved dates, so it stays correct even if
/// Taskie was closed at midnight. These properties are not stored in Isar.
extension TaskCalendar on Task {
  DateTime get scheduledDay {
    final date = (dueDate ?? createdAt).toLocal();
    return DateTime(date.year, date.month, date.day);
  }

  bool isScheduledFor(DateTime date) {
    final local = date.toLocal();
    return scheduledDay == DateTime(local.year, local.month, local.day);
  }

  bool isPreviousAt(DateTime now) {
    final local = now.toLocal();
    return scheduledDay.isBefore(DateTime(local.year, local.month, local.day));
  }

  bool isExpiredAt(DateTime now) {
    if (isCompleted) return false;
    final deadline = dueDate;
    // Without a reminder time, the task expires when its calendar day ends.
    return deadline == null ? isPreviousAt(now) : !deadline.isAfter(now);
  }
}
