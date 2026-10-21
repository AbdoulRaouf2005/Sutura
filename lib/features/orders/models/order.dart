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

  final String id;
  final String clientId;
  final String? garmentModelId;

  /// Copie historique du nom du modèle au moment de la commande.
  final String? modelNameSnapshot;

  /// Copie historique de la photo de référence, si nécessaire.
  final String? modelImageSnapshotPath;
  final String? measurementSetId;
  final String? description;
  final int quantity;

  /// Prix total convenu, en FCFA (entier).
  final int totalPrice;
  final DateTime deliveryAt;
  final OrderStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Une commande est en retard si elle n'est ni livrée ni annulée
  /// et que sa date de livraison est passée.
  bool isLate({DateTime? now}) =>
      status != OrderStatus.delivered &&
      status != OrderStatus.cancelled &&
      deliveryAt.isBefore(now ?? DateTime.now());

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
  }) =>
      Order(
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
        description:
            clearDescription ? null : (description ?? this.description),
        quantity: quantity ?? this.quantity,
        totalPrice: totalPrice ?? this.totalPrice,
        deliveryAt: deliveryAt ?? this.deliveryAt,
        status: status ?? this.status,
        notes: clearNotes ? null : (notes ?? this.notes),
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
