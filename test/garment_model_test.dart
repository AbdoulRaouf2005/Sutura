import 'package:flutter_test/flutter_test.dart';
import 'package:sutura/features/gallery/models/garment_model.dart';

void main() {
  group('GarmentModel', () {
    test('sérialise et désérialise sans perte', () {
      final GarmentModel model = GarmentModel(
        id: 'g1',
        name: 'Boubou brodé',
        category: 'Boubou',
        description: 'Broderie au col',
        localImagePath: '/data/garment_images/g1.jpg',
        createdAt: DateTime(2026, 2, 1),
        updatedAt: DateTime(2026, 2, 3),
      );

      final GarmentModel roundTrip = GarmentModel.fromMap(model.toMap());

      expect(roundTrip.id, model.id);
      expect(roundTrip.name, model.name);
      expect(roundTrip.category, model.category);
      expect(roundTrip.description, model.description);
      expect(roundTrip.localImagePath, model.localImagePath);
      expect(roundTrip.isArchived, isFalse);
    });

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

    test('copyWith efface la photo et la catégorie', () {
      final GarmentModel model = GarmentModel(
        id: 'g3',
        name: 'Kaftan',
        category: 'Kaftan',
        localImagePath: '/tmp/x.jpg',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final GarmentModel cleared =
          model.copyWith(clearImage: true, clearCategory: true);
      expect(cleared.localImagePath, isNull);
      expect(cleared.category, isNull);
      expect(cleared.name, 'Kaftan');
    });
  });

  test('les catégories par défaut n\'ont pas de doublon', () {
    expect(kGarmentCategories, isNotEmpty);
    expect(kGarmentCategories.toSet().length, kGarmentCategories.length);
  });
}
