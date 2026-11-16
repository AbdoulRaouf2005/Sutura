/// Modèle représentant un client de l'atelier.
///
/// Correspond à la table `clients` du cahier des charges (§4.2).
class Client {
  /// Crée une instance de [Client].
  ///
  /// [id] identifiant unique du client.
  /// [fullName] nom complet du client.
  /// [phone] numéro de téléphone optionnel.
  /// [notes] notes libres optionnelles.
  /// [createdAt] date de création de la fiche.
  /// [updatedAt] date de dernière mise à jour.
  /// [isArchived] indique si le client est archivé.
  const Client({
    required this.id,
    required this.fullName,
    this.phone,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
  });

  /// Identifiant unique du client.
  final String id;

  /// Nom complet du client.
  final String fullName;

  /// Numéro de téléphone du client, s'il est renseigné.
  final String? phone;

  /// Notes libres associées au client.
  final String? notes;

  /// Date de création de la fiche client.
  final DateTime createdAt;

  /// Date de dernière mise à jour de la fiche client.
  final DateTime updatedAt;

  /// Indique si le client est archivé.
  final bool isArchived;

  /// Construit un [Client] à partir d'une ligne de base de données [map].
  ///
  /// Retourne l'instance correspondante.
  factory Client.fromMap(Map<String, Object?> map) => Client(
    id: map['id'] as String,
    fullName: map['full_name'] as String,
    phone: map['phone'] as String?,
    notes: map['notes'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
    // Conversion de l'entier SQLite en booléen.
    isArchived: (map['is_archived'] as int? ?? 0) == 1,
  );

  /// Convertit le client en map pour la persistance en base de données.
  ///
  /// Retourne une map compatible avec SQLite.
  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'full_name': fullName,
    'phone': phone,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    // Conversion du booléen en entier pour SQLite.
    'is_archived': isArchived ? 1 : 0,
  };

  /// Crée une copie du client en remplaçant les champs fournis.
  ///
  /// [clearPhone] et [clearNotes] permettent d'effacer explicitement
  /// les champs optionnels. Retourne une nouvelle instance de [Client].
  Client copyWith({
    String? fullName,
    String? phone,
    String? notes,
    DateTime? updatedAt,
    bool? isArchived,
    bool clearPhone = false,
    bool clearNotes = false,
  }) => Client(
    id: id,
    fullName: fullName ?? this.fullName,
    phone: clearPhone ? null : (phone ?? this.phone),
    notes: clearNotes ? null : (notes ?? this.notes),
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isArchived: isArchived ?? this.isArchived,
  );
}
