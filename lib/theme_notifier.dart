import 'package:flutter/material.dart';
import 'theme.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkTheme;

  ThemeNotifier(this._isDarkTheme);

  bool get isDarkTheme => _isDarkTheme;

  void switchToLight() {
    _isDarkTheme = false;
    notifyListeners();
  }

  void switchToDark() {
    _isDarkTheme = true;
    notifyListeners();
  }
}
