import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

/// Manages theme mode (light/dark) with persistence via Hive.
///
/// Default is [ThemeMode.light] ("Kinetic High-Contrast Editorial").
/// User can toggle to [ThemeMode.dark] ("High-Performance Editorial")
/// and the preference is persisted across app restarts.
class ThemeProvider extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Initializes the provider by reading the persisted theme preference.
  Future<void> init() async {
    final box = await Hive.openBox(_boxName);
    final saved = box.get(_themeKey, defaultValue: 'light') as String;
    _themeMode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Toggles between light and dark mode and persists the change.
  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _persist();
    notifyListeners();
  }

  /// Sets a specific [ThemeMode] and persists the change.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final box = await Hive.openBox(_boxName);
    await box.put(_themeKey, _themeMode == ThemeMode.dark ? 'dark' : 'light');
  }
}
