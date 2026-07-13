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

  bool get isDueToday {
    if(dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year && dueDate!.month == now.month && dueDate!.day == now.day;
  }

  bool get isOverdue {
    if(dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  int get completedSubtaskCount => subtasks.where((s) => s.isCompleted).length;

  double get subtaskProgress {
    if(subtasks.isEmpty)return 0.0;
    return completedSubtaskCount / subtasks.length;
  }
}