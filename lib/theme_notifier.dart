import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeNotifier() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool("dark_mode") ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme(bool enabled) async {
    _isDarkMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("dark_mode", enabled);
    notifyListeners();
  }
}
