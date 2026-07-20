import 'package:flutter/material.dart';

/// Lets any nested screen (e.g. Home's quick-access cards) switch the
/// active bottom-navigation tab without needing a BuildContext hack.
class NavController extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void goToTab(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}
