import 'package:flutter/widgets.dart';

class OnboardingViewModel extends ChangeNotifier {
  final pageController = PageController();
  final nameController = TextEditingController();

  static const int pageCount = 4;

  int _currentPage = 0;
  int get currentPage => _currentPage;
  bool get isLastPage => _currentPage == pageCount -1;

  OnboardingViewModel() {
    nameController.addListener(notifyListeners);
  }

  void onPageChanged(int index) {
    _currentPage = index;
    notifyListeners();
  }

  void onNextPage() {
    pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    nameController.removeListener(notifyListeners);
    nameController.dispose();
    pageController.dispose();
    super.dispose();
  }
}