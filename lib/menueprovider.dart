import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MenueProvider with ChangeNotifier {
  int _selectedIndex = 1;
  final _pageController = PageController(initialPage: 1);
  List<String> _stringIngredients = [];

  PageController get pageController => _pageController;

  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
    if (kDebugMode) {
      print('$selectedIndex changed');
    }
  }

  List<String> get stringIngredients => _stringIngredients;

  void setStringIngredients(List<String> ingredients) {
    _stringIngredients = ingredients;
    notifyListeners();
  }
}
