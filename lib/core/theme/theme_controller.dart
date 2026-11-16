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
  /// Constructeur privé pour le singleton.
  ThemeController._();

  /// Instance unique du contrôleur de thème.
  static final ThemeController instance = ThemeController._();

  /// Clé utilisée pour persister le mode de thème dans les préférences.
  static const String _prefsKey = 'theme_mode';

  /// Mode de thème courant (clair par défaut pour la V1, guide §2).
  ThemeMode _themeMode = ThemeMode.light;

  /// Retourne le mode de thème actuellement appliqué.
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
  ///
  /// [systemIsDark] indique si le système est en mode sombre, utilisé lorsque
  /// le mode actuel est [ThemeMode.system].
  Future<void> toggleDark({required bool systemIsDark}) async {
    final bool isDark = switch (_themeMode) {
      ThemeMode.system => systemIsDark,
      ThemeMode.dark => true,
      ThemeMode.light => false,
    };
    await setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  /// Décode une chaîne [raw] en [ThemeMode], avec repli sur le mode clair.
  static ThemeMode _decode(String? raw) {
    return ThemeMode.values.firstWhere(
      (ThemeMode mode) => mode.name == raw,
      orElse: () => ThemeMode.light,
    );
  }
}
