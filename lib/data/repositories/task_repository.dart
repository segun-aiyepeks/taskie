import 'package:taskie/data/models/category.dart';
import 'package:taskie/data/models/task.dart';

abstract class TaskRepository {
  //Tasks
  Future<int> saveTask(Task task);
  Future<Task?> getTaskById(int id);
  Future<void> deleteTask(int id);
  Future<void> toggleTaskCompletion(int id);

  //Streams
  Stream<List<Task>> watchAllTasks();
  Stream<List<Task>> watchTodayTasks();
  Stream<List<Task>> watchTaskByCategory(int categoryId);

  //Categories
  Future<int> saveCategory(Category category);
  Future<void> deleteCategory(int id);
  Stream<List<Category>> watchAllCategories();

  //Stats
  Stream<Map<String, int>> watchStats();

  //Init
  Future<void> seeDefaultCategories();
}