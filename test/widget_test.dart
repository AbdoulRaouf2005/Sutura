import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:sutura/app/app.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  testWidgets('L\'application démarre sur l\'accueil', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SuturaApp());
    await tester.pump();

    expect(find.text('Accueil'), findsWidgets);
    expect(find.text('Clients'), findsWidgets);
    expect(find.text('Commandes'), findsWidgets);
    expect(find.text('Réglages'), findsWidgets);
  });
}
