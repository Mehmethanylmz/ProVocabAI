import 'package:flutter/material.dart';

class MainViewModel extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  // Sekmeyi değiştiren fonksiyon
  void changeTab(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}
