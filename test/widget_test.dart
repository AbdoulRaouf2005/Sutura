import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:sutura/app/app.dart';

void main() {
  // Initialise les formats de date en français avant de monter l'application.
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  /// Vérifie que l'application démarre sur l'accueil et affiche les onglets principaux.
  testWidgets('L\'application démarre sur l\'accueil', (
    WidgetTester tester,
  ) async {
    // Monte l'application puis laisse le premier rendu se stabiliser.
    await tester.pumpWidget(const SuturaApp());
    await tester.pump();

    expect(find.text('Accueil'), findsWidgets);
    expect(find.text('Clients'), findsWidgets);
    expect(find.text('Commandes'), findsWidgets);
    expect(find.text('Réglages'), findsWidgets);
  });
}
