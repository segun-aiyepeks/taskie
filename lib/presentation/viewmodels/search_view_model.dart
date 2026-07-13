import 'dart:async';

import 'package:flutter/material.dart';

class SearchViewModel extends ChangeNotifier {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  bool _isActive = false;
  Timer? _debounce;

  bool get isActivity => _isActive;
  bool get hasQuery => controller.text.isNotEmpty;

  void Function(String query)? onQueryChanged;

  SearchViewModel() {
    controller.addListener(_onChanged);
  }

  void _onChanged(){
    notifyListeners();

    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: 250), (){
      onQueryChanged?.call(controller.text.trim());
    });
  }

  void activate() {
    _isActive = true;
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  void deactivate() {
    _isActive = false;
    controller.clear();
    _debounce?.cancel();
    onQueryChanged?.call('');
    focusNode.unfocus();
    notifyListeners();
  }

  void clearText() {
    controller.clear();
    _debounce?.cancel();
    onQueryChanged?.call('');
    notifyListeners();
  }
}