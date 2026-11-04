import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sutura/app/app.dart';
import 'package:sutura/core/theme/app_theme.dart';
import 'package:sutura/core/theme/theme_controller.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ThemeController.instance.setThemeMode(ThemeMode.light);
  });

  test('le mode sombre est enregistré puis relu', () async {
    await ThemeController.instance.setThemeMode(ThemeMode.dark);
    expect(ThemeController.instance.themeMode, ThemeMode.dark);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');

    await ThemeController.instance.load();
    expect(ThemeController.instance.themeMode, ThemeMode.dark);
  });

  test('une préférence inconnue retombe sur le thème clair', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'theme_mode': 'inexistant',
    });
    await ThemeController.instance.load();
    expect(ThemeController.instance.themeMode, ThemeMode.light);
  });

  test('le thème sombre utilise des surfaces sombres', () {
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.dark.colorScheme.surface, isNot(AppTheme.light.colorScheme.surface));
  });

  testWidgets('le mode sombre est appliqué à l\'application', (
    WidgetTester tester,
  ) async {
    await ThemeController.instance.setThemeMode(ThemeMode.dark);
    await tester.pumpWidget(const SuturaApp());
    await tester.pump();

    final BuildContext context = tester.element(find.byType(NavigationBar));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('le mode clair est appliqué à l\'application', (
    WidgetTester tester,
  ) async {
    await ThemeController.instance.setThemeMode(ThemeMode.light);
    await tester.pumpWidget(const SuturaApp());
    await tester.pump();

    final BuildContext context = tester.element(find.byType(NavigationBar));
    expect(Theme.of(context).brightness, Brightness.light);
  });

  testWidgets('le sélecteur des réglages bascule en mode sombre', (
    WidgetTester tester,
  ) async {
    await ThemeController.instance.setThemeMode(ThemeMode.light);
    await tester.pumpWidget(const SuturaApp());
    await tester.pump();

    await tester.tap(find.text('Réglages'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Thème de l\'application'), findsOneWidget);

    await tester.tap(find.text('Sombre'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(ThemeController.instance.themeMode, ThemeMode.dark);

    final BuildContext context = tester.element(find.byType(NavigationBar));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
