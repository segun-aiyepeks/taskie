import 'package:isar/isar.dart';
import 'package:taskie/core/constants/app_enums.dart';
import 'package:taskie/data/models/category.dart';
import 'package:taskie/data/models/task.dart';
import 'package:taskie/data/repositories/task_repository.dart';

class IsarTaskRepository implements TaskRepository {
  final Isar _isar;

  IsarTaskRepository(this._isar);

  //TASKS
  //Saving tasks
  @override
  Future<int> saveTask(Task task) async {
    return _isar.writeTxn(() => _isar.collection<Task>().put(task));
  }

  //Getting tasks by Id
  @override
  Future<Task?> getTaskById(int id) => _isar.collection<Task>().get(id);
  
  //Deleting tasks
  @override
  Future<void> deleteTask(int id) async{
    await _isar.writeTxn(() => _isar.collection<Task>().delete(id));
    
  }

  //Toggling task completion
  @override
  Future<void> toggleTaskCompletion(int id) async{
    await _isar.writeTxn(() async{
      final task = await _isar.collection<Task>().get(id);
      if (task == null) return;

      if(task.isCompleted){
        task.status = TaskStatus.pending;
        task.completedAt = null;
      } else {
        task.status = TaskStatus.completed;
        task.completedAt = DateTime.now();
      }

      await _isar.collection<Task>().put(task);
    });
  }

  //Watch All the Tasks
  @override
  Stream<List<Task>> watchAllTasks() {
    return _isar.collection<Task>().where().sortByCreatedAtDesc().watch(fireImmediately: true);
  }

  //Watch Today's Tasks
   @override
  Stream<List<Task>> watchTodayTasks() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    return _isar.collection<Task>().filter().dueDateBetween(start, end).watch(fireImmediately: true);
  }

  //Watch Tasks by Category
   @override
  Stream<List<Task>> watchTaskByCategory(int categoryId) {
    return _isar.collection<Task>().filter().categoryIdEqualTo(categoryId).watch(fireImmediately: true);
  }

  // CATEGORIES
  //Saving Category
  @override
  Future<int> saveCategory(Category category) async{
    return _isar.writeTxn(() => _isar.collection<Category>().put(category));
  }

  //Deleting Category
  @override
  Future<void> deleteCategory(int id) async {
    await _isar.writeTxn(() async {
      final tasksWithCat = await _isar.collection<Task>().filter().categoryIdEqualTo(id).findAll();
      for (final task in tasksWithCat) {
        task.categoryId = 0;
        await _isar.collection<Task>().put(task);
      }
      await _isar.collection<Category>().delete(id);
    });
  }
   
  //Watching all categories
  @override
  Stream<List<Category>> watchAllCategories() {
    return _isar.collection<Category>().where().sortByName().watch(fireImmediately: true);
  }

  //STATS
  //Watching Stats
  @override
  Stream<Map<String, int>> watchStats() {
  return _isar.tasks
      .where()
      .watch(fireImmediately: true)
      .map((tasks) => {
            'total':     tasks.length,
            'completed': tasks.where((t) => t.isCompleted).length,
            'pending':   tasks.where((t) => t.isPending).length,
            'today':     tasks.where((t) => t.isDueToday).length,
            'high':      tasks.where((t) => t.priority == Priority.high).length,
            'medium':    tasks.where((t) => t.priority == Priority.medium).length,
            'low':       tasks.where((t) => t.priority == Priority.low).length,
          });
}

  //SEEDING
  @override
  Future<void> seeDefaultCategories() async{
    final collection = _isar.collection<Category>();
    final existingCategories = await collection.where().findAll();

    final defaults = [
      Category()
      ..name = 'Work'
      ..hexColor = '#4F67F8'
      ..iconName = 'briefcase',
      Category()
      ..name = 'Personal'
      ..hexColor = '#E09720'
      ..iconName = 'user',
      Category()
      ..name = 'Health'
      ..hexColor = '#2ABFA0'
      ..iconName = 'heart',
      Category()
      ..name = 'Study'
      ..hexColor = '#8570C8'
      ..iconName = 'book',
      Category()
      ..name = 'Business'
      ..hexColor = '#3E8E6D'
      ..iconName = 'briefcase'
    ];

    final categoriesToAdd = <Category>[];
    if (existingCategories.isEmpty) {
      categoriesToAdd.addAll(defaults);
    } else if (!existingCategories.any(
      (category) => category.name.toLowerCase() == 'business',
    )) {
      categoriesToAdd.add(defaults.last);
    }

    if (categoriesToAdd.isNotEmpty) {
      await _isar.writeTxn(() => collection.putAll(categoriesToAdd));
    }
  }  
}
