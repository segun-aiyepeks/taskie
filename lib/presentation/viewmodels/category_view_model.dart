import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taskie/data/models/category.dart';
import 'package:taskie/data/repositories/task_repository.dart';

class CategoryViewModel extends ChangeNotifier {
  final TaskRepository _repository;

  List<Category> _categories = [];
  StreamSubscription<List<Category>>? _sub;

  List<Category> get categories => _categories;

  CategoryViewModel(this._repository) {
    _sub = _repository.watchAllCategories().listen((cats) {
      _categories = cats;
      notifyListeners();
    });
  }

  // Lookups
  Category? getCategorybyId(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch(_) {
      return null;
    }
  }

  //Parsing the stored hex string
  Color getColorForCategory(int id) {
    final cat = getCategorybyId(id);
    if(cat == null) return Colors.grey;
    try {
      return Color(
        int.parse(cat.hexColor.replaceFirst('#', '0XFF'))
      );
    } catch(_){
      return Colors.grey;
    }
  }

  //CRUD
  Future<void> addCategory(Category category) async {
    await _repository.saveCategory(category);
  }

  Future<void> updateCategory(Category category) async {
    await _repository.saveCategory(category);
  }

  Future<void> deleteCategory(int id) async {
    await _repository.deleteCategory(id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}