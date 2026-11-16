import 'package:flutter_test/flutter_test.dart';
import 'package:sutura/features/measurements/models/measurement_set.dart';

void main() {
  /// Tests du modèle MeasurementSet : sérialisation complète.
  group('MeasurementSet', () {
    /// Vérifie qu'un aller-retour toMap/fromMap conserve tous les champs.
    test('sérialise et désérialise sans perte', () {
      // Ensemble de mesures servant de référence pour le round-trip.
      final MeasurementSet set = MeasurementSet(
        id: 's1',
        clientId: 'c1',
        garmentType: 'Boubou',
        notes: 'Mesures debout',
        measuredAt: DateTime(2026, 4, 10),
        createdAt: DateTime(2026, 4, 10, 12),
      );

      // Reconstruit l'ensemble à partir de sa représentation en map.
      final MeasurementSet roundTrip = MeasurementSet.fromMap(set.toMap());

      expect(roundTrip.id, set.id);
      expect(roundTrip.clientId, set.clientId);
      expect(roundTrip.garmentType, set.garmentType);
      expect(roundTrip.notes, set.notes);
      expect(roundTrip.measuredAt, set.measuredAt);
      expect(roundTrip.createdAt, set.createdAt);
    });
  });

  /// Tests d'une mesure individuelle : valeur et unité.
  group('Measurement', () {
    /// Vérifie que la valeur numérique est conservée et que l'unité par défaut est "cm".
    test('conserve la valeur numérique et l\'unité par défaut', () {
      const Measurement m = Measurement(
        id: 'm1',
        measurementSetId: 's1',
        name: 'Tour de poitrine',
        value: 92.5,
      );
      expect(m.unit, 'cm');

      final Measurement roundTrip = Measurement.fromMap(m.toMap());
      expect(roundTrip.value, 92.5);
      expect(roundTrip.name, 'Tour de poitrine');
      expect(roundTrip.unit, 'cm');
    });

    /// Vérifie qu'une unité personnalisée fournie dans la map est bien lue.
    test('lit une unité personnalisée', () {
      final Measurement m = Measurement.fromMap(<String, Object?>{
        'id': 'm2',
        'measurement_set_id': 's1',
        'name': 'Longueur',
        'value': 100,
        'unit': 'in',
      });
      expect(m.unit, 'in');
      expect(m.value, 100.0);
    });
  });

  /// Vérifie que la liste des noms par défaut n'est pas vide et sans doublon.
  test('la liste par défaut n\'est pas vide et ne contient pas de doublon', () {
    expect(kDefaultMeasurementNames, isNotEmpty);
    expect(
      kDefaultMeasurementNames.toSet().length,
      kDefaultMeasurementNames.length,
    );
  });
}
