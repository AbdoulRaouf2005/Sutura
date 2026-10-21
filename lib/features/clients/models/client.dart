/// Client — cahier des charges §4.2 / table `clients`.
class Client {
  const Client({
    required this.id,
    required this.fullName,
    this.phone,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
  });

  final String id;
  final String fullName;
  final String? phone;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;

  factory Client.fromMap(Map<String, Object?> map) => Client(
        id: map['id'] as String,
        fullName: map['full_name'] as String,
        phone: map['phone'] as String?,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        isArchived: (map['is_archived'] as int? ?? 0) == 1,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'full_name': fullName,
        'phone': phone,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'is_archived': isArchived ? 1 : 0,
      };

  Client copyWith({
    String? fullName,
    String? phone,
    String? notes,
    DateTime? updatedAt,
    bool? isArchived,
    bool clearPhone = false,
    bool clearNotes = false,
  }) =>
      Client(
        id: id,
        fullName: fullName ?? this.fullName,
        phone: clearPhone ? null : (phone ?? this.phone),
        notes: clearNotes ? null : (notes ?? this.notes),
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isArchived: isArchived ?? this.isArchived,
      );
}
