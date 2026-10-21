import 'package:flutter_test/flutter_test.dart';
import 'package:sutura/features/clients/models/client.dart';

void main() {
  group('Client', () {
    test('sérialise et désérialise sans perte', () {
      final Client client = Client(
        id: 'c1',
        fullName: 'Awa Diop',
        phone: '77 123 45 67',
        notes: 'Préfère les tissus légers',
        createdAt: DateTime(2026, 3, 1, 9, 30),
        updatedAt: DateTime(2026, 3, 2, 10),
      );

      final Client roundTrip = Client.fromMap(client.toMap());

      expect(roundTrip.id, client.id);
      expect(roundTrip.fullName, client.fullName);
      expect(roundTrip.phone, client.phone);
      expect(roundTrip.notes, client.notes);
      expect(roundTrip.createdAt, client.createdAt);
      expect(roundTrip.updatedAt, client.updatedAt);
      expect(roundTrip.isArchived, isFalse);
    });

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
