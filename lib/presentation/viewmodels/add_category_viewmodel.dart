import 'package:flutter/material.dart';
import 'package:taskie/core/constants/app_colors.dart';

class AddCategoryViewModel extends ChangeNotifier {
  final nameController = TextEditingController();

  Color _selectedColor = AppColors.primary;
  String _selectedIcon = 'folder';

  Color get selectedColor => _selectedColor;
  String get selectedIcon => _selectedIcon;
  bool get canSave => nameController.text.trim().isNotEmpty;

  // Predefined palette — user picks from these
  static const List<Color> palette = [
    Color(0xFF4F67F8),
    Color(0xFF2ABFA0),
    Color(0xFFE09720),
    Color(0xFFE84D2C),
    Color(0xFF8570C8),
    Color(0xFF3B9EDB),
    Color(0xFF27AE60),
    Color(0xFFE91E8C),
  ];

  // Predefined icons — name maps to a Material icon
  static const Map<String, IconData> icons = {
    'folder':    Icons.folder_outlined,
    'briefcase': Icons.work_outline_rounded,
    'heart':     Icons.favorite_outline_rounded,
    'book':      Icons.book_outlined,
    'star':      Icons.star_outline_rounded,
    'home':      Icons.home_outlined,
    'fitness':   Icons.fitness_center_outlined,
    'cart':      Icons.shopping_cart_outlined,
  };

  AddCategoryViewModel(){
    nameController.addListener(notifyListeners);
  }

  void setColor(Color color) {
    _selectedColor = color;
    notifyListeners();
  }

  void setIcon(String iconName) {
    _selectedIcon = iconName;
    notifyListeners();
  }

  String get colorHex {
    final hex = (_selectedColor.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
    return '#$hex';
  }

  @override
  void dispose() {
    nameController.removeListener(notifyListeners);
    nameController.dispose();
    super.dispose();
  }
}