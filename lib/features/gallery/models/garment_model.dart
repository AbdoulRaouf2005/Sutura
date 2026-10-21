/// Modèle de vêtement de la galerie — table `garment_models`.
class GarmentModel {
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

  final String id;
  final String name;
  final String? category;
  final String? description;
  final String? localImagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;

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
  }) =>
      GarmentModel(
        id: id,
        name: name ?? this.name,
        category: clearCategory ? null : (category ?? this.category),
        description:
            clearDescription ? null : (description ?? this.description),
        localImagePath:
            clearImage ? null : (localImagePath ?? this.localImagePath),
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
