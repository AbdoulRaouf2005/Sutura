/// Statuts d'une commande (cahier des charges §4.5).
///
/// « En retard » n'est pas un statut enregistré mais un état calculé
/// (`Order.isLate`).
enum OrderStatus {
  toStart('to_start', 'À commencer'),
  inProgress('in_progress', 'En cours'),
  ready('ready', 'Prête'),
  delivered('delivered', 'Livrée'),
  cancelled('cancelled', 'Annulée');

  const OrderStatus(this.value, this.label);

  /// Valeur stockée en base.
  final String value;

  /// Libellé affiché en français.
  final String label;

  static OrderStatus fromValue(String value) => OrderStatus.values.firstWhere(
    (OrderStatus s) => s.value == value,
    orElse: () => OrderStatus.toStart,
  );
}

/// Commande — table `orders` (cahier des charges §4.5).
class Order {
  /// Crée une instance de commande.
  const Order({
    required this.id,
    required this.clientId,
    this.garmentModelId,
    this.modelNameSnapshot,
    this.modelImageSnapshotPath,
    this.measurementSetId,
    this.description,
    this.quantity = 1,
    required this.totalPrice,
    required this.deliveryAt,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Identifiant unique de la commande.
  final String id;

  /// Identifiant du client associé.
  final String clientId;

  /// Identifiant du modèle de vêtement associé, le cas échéant.
  final String? garmentModelId;

  /// Copie historique du nom du modèle au moment de la commande.
  final String? modelNameSnapshot;

  /// Copie historique de la photo de référence, si nécessaire.
  final String? modelImageSnapshotPath;

  /// Identifiant du jeu de mensurations associé.
  final String? measurementSetId;

  /// Description libre de la commande.
  final String? description;

  /// Quantité commandée.
  final int quantity;

  /// Prix total convenu, en FCFA (entier).
  final int totalPrice;

  /// Date de livraison prévue.
  final DateTime deliveryAt;

  /// Statut courant de la commande.
  final OrderStatus status;

  /// Notes complémentaires.
  final String? notes;

  /// Date de création de la commande.
  final DateTime createdAt;

  /// Date de dernière mise à jour de la commande.
  final DateTime updatedAt;

  /// Indique si la commande est en retard par rapport à [now].
  ///
  /// Une commande est en retard si elle n'est ni livrée ni annulée
  /// et que sa date de livraison est dépassée.
  bool isLate({DateTime? now}) =>
      status != OrderStatus.delivered &&
      status != OrderStatus.cancelled &&
      deliveryAt.isBefore(now ?? DateTime.now());

  /// Construit une commande à partir d'une ligne de base de données [map].
  factory Order.fromMap(Map<String, Object?> map) => Order(
    id: map['id'] as String,
    clientId: map['client_id'] as String,
    garmentModelId: map['garment_model_id'] as String?,
    modelNameSnapshot: map['model_name_snapshot'] as String?,
    modelImageSnapshotPath: map['model_image_snapshot_path'] as String?,
    measurementSetId: map['measurement_set_id'] as String?,
    description: map['description'] as String?,
    quantity: map['quantity'] as int? ?? 1,
    totalPrice: map['total_price'] as int,
    deliveryAt: DateTime.parse(map['delivery_at'] as String),
    status: OrderStatus.fromValue(map['status'] as String),
    notes: map['notes'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  /// Convertit la commande en map pour l'enregistrement en base de données.
  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'client_id': clientId,
    'garment_model_id': garmentModelId,
    'model_name_snapshot': modelNameSnapshot,
    'model_image_snapshot_path': modelImageSnapshotPath,
    'measurement_set_id': measurementSetId,
    'description': description,
    'quantity': quantity,
    'total_price': totalPrice,
    'delivery_at': deliveryAt.toIso8601String(),
    'status': status.value,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  /// Retourne une copie de la commande avec les champs fournis modifiés.
  Order copyWith({
    String? garmentModelId,
    String? modelNameSnapshot,
    String? modelImageSnapshotPath,
    String? measurementSetId,
    String? description,
    int? quantity,
    int? totalPrice,
    DateTime? deliveryAt,
    OrderStatus? status,
    String? notes,
    DateTime? updatedAt,
    bool clearModel = false,
    bool clearMeasurementSet = false,
    bool clearDescription = false,
    bool clearNotes = false,
  }) => Order(
    id: id,
    clientId: clientId,
    garmentModelId: clearModel ? null : (garmentModelId ?? this.garmentModelId),
    modelNameSnapshot: clearModel
        ? null
        : (modelNameSnapshot ?? this.modelNameSnapshot),
    modelImageSnapshotPath: clearModel
        ? null
        : (modelImageSnapshotPath ?? this.modelImageSnapshotPath),
    measurementSetId: clearMeasurementSet
        ? null
        : (measurementSetId ?? this.measurementSetId),
    description: clearDescription ? null : (description ?? this.description),
    quantity: quantity ?? this.quantity,
    totalPrice: totalPrice ?? this.totalPrice,
    deliveryAt: deliveryAt ?? this.deliveryAt,
    status: status ?? this.status,
    notes: clearNotes ? null : (notes ?? this.notes),
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// Commande accompagnée du nom de son client.
///
/// Utilisé par les listes qui affichent les deux informations : le nom est
/// récupéré par jointure, sans requête supplémentaire par commande.
class OrderWithClient {
  /// Crée une association commande-client.
  const OrderWithClient({required this.order, required this.clientName});

  /// Commande concernée.
  final Order order;

  /// Nom du client associé à la commande.
  final String clientName;
}
