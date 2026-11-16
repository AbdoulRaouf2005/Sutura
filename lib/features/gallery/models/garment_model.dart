/// Modèle de vêtement de la galerie — table `garment_models`.
///
/// Représente un modèle de couture (photo + métadonnées) réutilisable
/// lors de la création d'une commande.
class GarmentModel {
  /// Crée un modèle de vêtement.
  ///
  /// Seuls [id], [name], [createdAt] et [updatedAt] sont obligatoires ;
  /// [category], [description] et [localImagePath] peuvent rester nuls.
  /// [isArchived] vaut `false` par défaut.
  const GarmentModel({
    required this.id,
    required this.name,
    this.category,
    this.description,
    this.localImagePath,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
  });

  /// Identifiant unique du modèle.
  final String id;

  /// Nom affiché du modèle.
  final String name;

  /// Catégorie du vêtement (voir [kGarmentCategories]), facultative.
  final String? category;

  /// Description ou notes libres sur le modèle.
  final String? description;

  /// Chemin local de la photo enregistrée sur l'appareil.
  final String? localImagePath;

  /// Date de création de l'enregistrement.
  final DateTime createdAt;

  /// Date de la dernière modification.
  final DateTime updatedAt;

  /// Indique si le modèle est archivé (masqué des nouvelles commandes).
  final bool isArchived;

  /// Construit un modèle à partir d'une ligne de base de données.
  ///
  /// La colonne `is_archived` est stockée en entier (`1` = archivé).
  factory GarmentModel.fromMap(Map<String, Object?> map) => GarmentModel(
    id: map['id'] as String,
    name: map['name'] as String,
    category: map['category'] as String?,
    description: map['description'] as String?,
    localImagePath: map['local_image_path'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
    isArchived: (map['is_archived'] as int? ?? 0) == 1,
  );

  /// Convertit le modèle en map prête à être persistée.
  ///
  /// `is_archived` est enregistré sous forme d'entier (`1`/`0`).
  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'name': name,
    'category': category,
    'description': description,
    'local_image_path': localImagePath,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'is_archived': isArchived ? 1 : 0,
  };

  /// Renvoie une copie du modèle avec les champs indiqués remplacés.
  ///
  /// Les drapeaux [clearCategory], [clearDescription] et [clearImage]
  /// permettent de remettre explicitement un champ facultatif à `null`.
  GarmentModel copyWith({
    String? name,
    String? category,
    String? description,
    String? localImagePath,
    DateTime? updatedAt,
    bool? isArchived,
    bool clearCategory = false,
    bool clearDescription = false,
    bool clearImage = false,
  }) => GarmentModel(
    id: id,
    name: name ?? this.name,
    category: clearCategory ? null : (category ?? this.category),
    description: clearDescription ? null : (description ?? this.description),
    localImagePath: clearImage ? null : (localImagePath ?? this.localImagePath),
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isArchived: isArchived ?? this.isArchived,
  );
}

/// Catégories de départ — à ajuster avec le couturier (§4.4).
const List<String> kGarmentCategories = <String>[
  'Boubou',
  'Kaftan',
  'Robe',
  'Chemise',
  'Pantalon',
  'Tenue traditionnelle',
  'Autre',
];
