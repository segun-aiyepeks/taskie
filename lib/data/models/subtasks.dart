import 'package:isar/isar.dart';

part 'subtasks.g.dart';

@embedded
class Subtasks {
  String subtaskId = '';
  String title = '';
  bool isCompleted = false;
  DateTime? createdAt;
}