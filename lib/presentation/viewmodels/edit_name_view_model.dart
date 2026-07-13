import 'package:flutter/widgets.dart';

class EditNameViewModel extends ChangeNotifier {
  final TextEditingController nameController;

  EditNameViewModel(String? initialName): nameController = TextEditingController(text: initialName ?? '');

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}