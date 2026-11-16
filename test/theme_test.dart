import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sutura/app/app.dart';
import 'package:sutura/core/theme/app_theme.dart';
import 'package:sutura/core/theme/theme_controller.dart';

void main() {
  // Remet un état propre avant chaque test : préférences vides et thème clair.
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ThemeController.instance.setThemeMode(ThemeMode.light);
  });

  /// Vérifie que le mode sombre est persisté puis rechargé correctement.
  test('le mode sombre est enregistré puis relu', () async {
    await ThemeController.instance.setThemeMode(ThemeMode.dark);
    expect(ThemeController.instance.themeMode, ThemeMode.dark);

    // Contrôle direct de la valeur écrite dans les préférences.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');

    await ThemeController.instance.load();
    expect(ThemeController.instance.themeMode, ThemeMode.dark);
  });

  /// Vérifie qu'une préférence invalide retombe sur le thème clair.
  test('une préférence inconnue retombe sur le thème clair', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'theme_mode': 'inexistant',
    });
    await ThemeController.instance.load();
    expect(ThemeController.instance.themeMode, ThemeMode.light);
  });

  /// Vérifie que le thème sombre expose bien des surfaces sombres distinctes.
  test('le thème sombre utilise des surfaces sombres', () {
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(
      AppTheme.dark.colorScheme.surface,
      isNot(AppTheme.light.colorScheme.surface),
    );
  });

  /// Vérifie que le mode sombre configuré est appliqué à l'application montée.
  testWidgets('le mode sombre est appliqué à l\'application', (
    WidgetTester tester,
  ) async {
    await ThemeController.instance.setThemeMode(ThemeMode.dark);
    await tester.pumpWidget(const SuturaApp());
    await tester.pump();

    // Récupère le contexte depuis la barre de navigation pour lire le thème actif.
    final BuildContext context = tester.element(find.byType(NavigationBar));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  /// Vérifie que le mode clair configuré est appliqué à l'application montée.
  testWidgets('le mode clair est appliqué à l\'application', (
    WidgetTester tester,
  ) async {
    await ThemeController.instance.setThemeMode(ThemeMode.light);
    await tester.pumpWidget(const SuturaApp());
    await tester.pump();

    // Récupère le contexte depuis la barre de navigation pour lire le thème actif.
    final BuildContext context = tester.element(find.byType(NavigationBar));
    expect(Theme.of(context).brightness, Brightness.light);
  });

  /// Vérifie que le sélecteur des réglages bascule effectivement en mode sombre.
  testWidgets('le sélecteur des réglages bascule en mode sombre', (
    WidgetTester tester,
  ) async {
    await ThemeController.instance.setThemeMode(ThemeMode.light);
    await tester.pumpWidget(const SuturaApp());
    await tester.pump();

    // Ouvre l'onglet Réglages et attend la fin de l'animation.
    await tester.tap(find.text('Réglages'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Thème de l\'application'), findsOneWidget);

    // Sélectionne le thème sombre puis laisse l'interface se mettre à jour.
    await tester.tap(find.text('Sombre'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(ThemeController.instance.themeMode, ThemeMode.dark);

    final BuildContext context = tester.element(find.byType(NavigationBar));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
