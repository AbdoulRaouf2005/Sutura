import 'package:flutter_test/flutter_test.dart';
import 'package:sutura/features/gallery/models/garment_model.dart';

void main() {
  /// Tests du modèle GarmentModel : sérialisation, optionnels et archivage.
  group('GarmentModel', () {
    /// Vérifie qu'un aller-retour toMap/fromMap conserve tous les champs.
    test('sérialise et désérialise sans perte', () {
      // Modèle complet servant de référence pour le round-trip.
      final GarmentModel model = GarmentModel(
        id: 'g1',
        name: 'Boubou brodé',
        category: 'Boubou',
        description: 'Broderie au col',
        localImagePath: '/data/garment_images/g1.jpg',
        createdAt: DateTime(2026, 2, 1),
        updatedAt: DateTime(2026, 2, 3),
      );

      // Reconstruit le modèle à partir de sa représentation en map.
      final GarmentModel roundTrip = GarmentModel.fromMap(model.toMap());

      expect(roundTrip.id, model.id);
      expect(roundTrip.name, model.name);
      expect(roundTrip.category, model.category);
      expect(roundTrip.description, model.description);
      expect(roundTrip.localImagePath, model.localImagePath);
      expect(roundTrip.isArchived, isFalse);
    });

    /// Vérifie que les champs absents valent null et que l'archivage est stocké en entier.
    test('gère les champs optionnels et l\'archivage', () {
      final GarmentModel model = GarmentModel(
        id: 'g2',
        name: 'Robe simple',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        isArchived: true,
      );
      final Map<String, Object?> map = model.toMap();
      expect(map['category'], isNull);
      expect(map['description'], isNull);
      expect(map['local_image_path'], isNull);
      expect(map['is_archived'], 1);
    });

    /// Vérifie que copyWith peut effacer la photo et la catégorie.
    test('copyWith efface la photo et la catégorie', () {
      final GarmentModel model = GarmentModel(
        id: 'g3',
        name: 'Kaftan',
        category: 'Kaftan',
        localImagePath: '/tmp/x.jpg',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final GarmentModel cleared = model.copyWith(
        clearImage: true,
        clearCategory: true,
      );
      expect(cleared.localImagePath, isNull);
      expect(cleared.category, isNull);
      expect(cleared.name, 'Kaftan');
    });
  });

  /// Vérifie que la liste des catégories par défaut n'est pas vide et sans doublon.
  test('les catégories par défaut n\'ont pas de doublon', () {
    expect(kGarmentCategories, isNotEmpty);
    expect(kGarmentCategories.toSet().length, kGarmentCategories.length);
  });
}
