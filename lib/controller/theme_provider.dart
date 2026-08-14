import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/settings_service.dart';

class ThemeController extends GetxController {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  @override
  void onInit() {
    super.onInit();
    loadTheme();
  }

  Future<void> loadTheme() async {
    final saved = await SettingsService.loadThemeMode();
    _themeMode = _parseThemeMode(saved);
    update();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await SettingsService.saveThemeMode(mode.name);
    update();
  }

  Future<void> toggleTheme(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  static ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
