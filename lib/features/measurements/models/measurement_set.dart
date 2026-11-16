/// Modèle représentant un jeu de mensurations pour un client.
///
/// Correspond à la table `measurement_sets`.
class MeasurementSet {
  /// Crée une instance de [MeasurementSet].
  ///
  /// [id] identifiant unique du jeu.
  /// [clientId] identifiant du client associé.
  /// [garmentType] type de vêtement ou usage des mesures.
  /// [notes] notes optionnelles.
  /// [measuredAt] date de prise des mesures.
  /// [createdAt] date de création de l'enregistrement.
  const MeasurementSet({
    required this.id,
    required this.clientId,
    required this.garmentType,
    this.notes,
    required this.measuredAt,
    required this.createdAt,
  });

  /// Identifiant unique du jeu de mensurations.
  final String id;

  /// Identifiant du client auquel appartient ce jeu.
  final String clientId;

  /// Type de vêtement ou usage des mesures (ex. « Boubou »).
  final String garmentType;

  /// Notes libres associées au jeu de mensurations.
  final String? notes;

  /// Date à laquelle les mesures ont été prises.
  final DateTime measuredAt;

  /// Date de création de l'enregistrement en base.
  final DateTime createdAt;

  /// Construit un [MeasurementSet] à partir d'une ligne de base de données [map].
  ///
  /// Retourne l'instance correspondante.
  factory MeasurementSet.fromMap(Map<String, Object?> map) => MeasurementSet(
    id: map['id'] as String,
    clientId: map['client_id'] as String,
    garmentType: map['garment_type'] as String,
    notes: map['notes'] as String?,
    measuredAt: DateTime.parse(map['measured_at'] as String),
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  /// Convertit le jeu de mensurations en map pour la persistance.
  ///
  /// Retourne une map compatible avec SQLite.
  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'client_id': clientId,
    'garment_type': garmentType,
    'notes': notes,
    'measured_at': measuredAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };
}

/// Modèle représentant une mesure individuelle d'un jeu de mensurations.
///
/// Correspond à la table `measurements`.
class Measurement {
  /// Crée une instance de [Measurement].
  ///
  /// [id] identifiant unique de la mesure.
  /// [measurementSetId] identifiant du jeu parent.
  /// [name] nom de la mesure.
  /// [value] valeur numérique de la mesure.
  /// [unit] unité de mesure (par défaut « cm »).
  const Measurement({
    required this.id,
    required this.measurementSetId,
    required this.name,
    required this.value,
    this.unit = 'cm',
  });

  /// Identifiant unique de la mesure.
  final String id;

  /// Identifiant du jeu de mensurations parent.
  final String measurementSetId;

  /// Nom de la mesure (ex. tour de poitrine).
  final String name;

  /// Valeur numérique de la mesure.
  final double value;

  /// Unité de la mesure.
  final String unit;

  /// Construit une [Measurement] à partir d'une ligne de base de données [map].
  ///
  /// Retourne l'instance correspondante.
  factory Measurement.fromMap(Map<String, Object?> map) => Measurement(
    id: map['id'] as String,
    measurementSetId: map['measurement_set_id'] as String,
    name: map['name'] as String,
    value: (map['value'] as num).toDouble(),
    unit: map['unit'] as String? ?? 'cm',
  );

  /// Convertit la mesure en map pour la persistance.
  ///
  /// Retourne une map compatible avec SQLite.
  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'measurement_set_id': measurementSetId,
    'name': name,
    'value': value,
    'unit': unit,
  };
}

/// Liste de départ des mesures proposée par défaut dans le formulaire.
///
/// À valider avec le couturier (§4.3 — ne pas la présenter comme définitive).
const List<String> kDefaultMeasurementNames = <String>[
  'Tour de poitrine',
  'Tour de taille',
  'Tour de hanches',
  'Longueur',
  'Épaules',
  'Manche',
  'Cou',
];
