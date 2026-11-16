import 'package:flutter_test/flutter_test.dart';
import 'package:sutura/features/clients/models/client.dart';

void main() {
  /// Tests du modèle Client : sérialisation, champs optionnels et archivage.
  group('Client', () {
    /// Vérifie qu'un aller-retour toMap/fromMap conserve tous les champs.
    test('sérialise et désérialise sans perte', () {
      // Client complet servant de référence pour le round-trip.
      final Client client = Client(
        id: 'c1',
        fullName: 'Awa Diop',
        phone: '77 123 45 67',
        notes: 'Préfère les tissus légers',
        createdAt: DateTime(2026, 3, 1, 9, 30),
        updatedAt: DateTime(2026, 3, 2, 10),
      );

      // Reconstruit le client à partir de sa représentation en map.
      final Client roundTrip = Client.fromMap(client.toMap());

      expect(roundTrip.id, client.id);
      expect(roundTrip.fullName, client.fullName);
      expect(roundTrip.phone, client.phone);
      expect(roundTrip.notes, client.notes);
      expect(roundTrip.createdAt, client.createdAt);
      expect(roundTrip.updatedAt, client.updatedAt);
      expect(roundTrip.isArchived, isFalse);
    });

    /// Vérifie que les champs optionnels absents sont sérialisés en null.
    test('gère les champs optionnels absents', () {
      final Client client = Client(
        id: 'c2',
        fullName: 'Moussa Ba',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final Map<String, Object?> map = client.toMap();
      expect(map['phone'], isNull);
      expect(map['notes'], isNull);
      expect(map['is_archived'], 0);
    });

    /// Vérifie que copyWith peut remettre le téléphone à null.
    test('copyWith permet d\'effacer un champ optionnel', () {
      final Client client = Client(
        id: 'c3',
        fullName: 'Fatou Ndiaye',
        phone: '76 000 00 00',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final Client cleared = client.copyWith(clearPhone: true);
      expect(cleared.phone, isNull);
      expect(cleared.fullName, 'Fatou Ndiaye');
    });

    /// Vérifie que copyWith active le drapeau d'archivage.
    test('archive un client via copyWith', () {
      final Client client = Client(
        id: 'c4',
        fullName: 'Ibrahima Sow',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(client.copyWith(isArchived: true).isArchived, isTrue);
    });
  });
}
