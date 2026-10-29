enum Priority {
  low,
  medium,
  high;

  String get label => switch (this) {
    Priority.low => 'Low',
    Priority.medium => 'Medium',
    Priority.high => 'High',
  };
  int get colorValue => switch (this) {
    Priority.low => 0xFF2ABFA0,
    Priority.medium => 0xFFE09720,
    Priority.high => 0xFFE84D2C,
  };
}

enum TaskStatus { pending, completed }

enum TaskFilter { all, today, pending, completed, expired }

enum TaskSortOption {
  createdAt('Recently Added'),
  dueDate('Due Date'),
  priority('Priority'),
  title('Alphabetical');

  final String label;
  const TaskSortOption(this.label);
}
