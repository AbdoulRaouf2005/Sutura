/// Jeu de mensurations — table `measurement_sets`.
class MeasurementSet {
  const MeasurementSet({
    required this.id,
    required this.clientId,
    required this.garmentType,
    this.notes,
    required this.measuredAt,
    required this.createdAt,
  });

  final String id;
  final String clientId;

  /// Type de vêtement ou usage des mesures (ex. « Boubou »).
  final String garmentType;
  final String? notes;
  final DateTime measuredAt;
  final DateTime createdAt;

  factory MeasurementSet.fromMap(Map<String, Object?> map) => MeasurementSet(
        id: map['id'] as String,
        clientId: map['client_id'] as String,
        garmentType: map['garment_type'] as String,
        notes: map['notes'] as String?,
        measuredAt: DateTime.parse(map['measured_at'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'client_id': clientId,
        'garment_type': garmentType,
        'notes': notes,
        'measured_at': measuredAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}

/// Mesure individuelle — table `measurements`.
class Measurement {
  const Measurement({
    required this.id,
    required this.measurementSetId,
    required this.name,
    required this.value,
    this.unit = 'cm',
  });

  final String id;
  final String measurementSetId;
  final String name;
  final double value;
  final String unit;

  factory Measurement.fromMap(Map<String, Object?> map) => Measurement(
        id: map['id'] as String,
        measurementSetId: map['measurement_set_id'] as String,
        name: map['name'] as String,
        value: (map['value'] as num).toDouble(),
        unit: map['unit'] as String? ?? 'cm',
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'measurement_set_id': measurementSetId,
        'name': name,
        'value': value,
        'unit': unit,
      };
}

/// Liste de départ des mesures, à valider avec le couturier
/// (cahier des charges §4.3 — ne pas la présenter comme définitive).
const List<String> kDefaultMeasurementNames = <String>[
  'Tour de poitrine',
  'Tour de taille',
  'Tour de hanches',
  'Longueur',
  'Épaules',
  'Manche',
  'Cou',
];
