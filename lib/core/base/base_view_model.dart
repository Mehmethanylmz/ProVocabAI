import 'package:flutter/material.dart';

abstract class BaseViewModel extends ChangeNotifier {
  BuildContext? context;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setContext(BuildContext context) {
    this.context = context;
  }

  void init() {}

  void changeLoading() {
    _isLoading = !_isLoading;
    notifyListeners();
  }
}
