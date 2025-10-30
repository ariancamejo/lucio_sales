import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';
  final SharedPreferences _prefs;

  ThemeService(this._prefs);

  ThemeMode getThemeMode() {
    final themeModeString = _prefs.getString(_themeKey);
    if (themeModeString == null) return ThemeMode.system;

    return ThemeMode.values.firstWhere(
      (mode) => mode.toString() == themeModeString,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    await _prefs.setString(_themeKey, themeMode.toString());
  }

  Future<void> toggleTheme() async {
    final currentMode = getThemeMode();
    final newMode = currentMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }
}
