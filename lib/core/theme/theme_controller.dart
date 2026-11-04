import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gère le mode de thème de l'application (clair, sombre ou système) et sa
/// persistance locale (cahier des charges §4.7 — préférences).
///
/// Utilisation :
/// - `await ThemeController.instance.load()` avant `runApp` ;
/// - `themeMode: ThemeController.instance.themeMode` sur le `MaterialApp` ;
/// - `ThemeController.instance.setThemeMode(mode)` depuis les réglages.
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const String _prefsKey = 'theme_mode';

  /// Le thème clair reste prioritaire pour la V1 (guide §2).
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  /// Lit la préférence enregistrée. À appeler une fois au démarrage.
  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _themeMode = _decode(prefs.getString(_prefsKey));
  }

  /// Applique un mode de thème et l'enregistre.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }

  /// Bascule entre clair et sombre en partant du mode courant.
  Future<void> toggleDark({required bool systemIsDark}) async {
    final bool isDark = switch (_themeMode) {
      ThemeMode.system => systemIsDark,
      ThemeMode.dark => true,
      ThemeMode.light => false,
    };
    await setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  static ThemeMode _decode(String? raw) {
    return ThemeMode.values.firstWhere(
      (ThemeMode mode) => mode.name == raw,
      orElse: () => ThemeMode.light,
    );
  }
}
