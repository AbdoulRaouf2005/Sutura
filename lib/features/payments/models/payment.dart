/// Méthodes de paiement facultatives (§4.6).
enum PaymentMethod {
  /// Paiement en espèces.
  cash('cash', 'Espèces'),

  /// Paiement par transfert.
  transfer('transfer', 'Transfert'),

  /// Autre méthode de paiement.
  other('other', 'Autre');

  /// Crée une méthode de paiement avec sa valeur et son libellé.
  const PaymentMethod(this.value, this.label);

  /// Valeur stockée en base de données.
  final String value;

  /// Libellé affiché en français.
  final String label;

  /// Retourne la méthode correspondant à [value], ou `null` si absente.
  static PaymentMethod? fromValue(String? value) {
    if (value == null) return null;
    for (final PaymentMethod m in PaymentMethod.values) {
      if (m.value == value) return m;
    }
    return null;
  }
}

/// Paiement (avance ou versement) — table `payments`.
class Payment {
  /// Crée une instance de paiement.
  const Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.paidAt,
    this.method,
    this.note,
  });

  /// Identifiant unique du paiement.
  final String id;

  /// Identifiant de la commande concernée.
  final String orderId;

  /// Montant versé, en FCFA (entier, strictement supérieur à zéro).
  final int amount;

  /// Date du versement.
  final DateTime paidAt;

  /// Méthode de paiement utilisée, le cas échéant.
  final PaymentMethod? method;

  /// Note associée au paiement.
  final String? note;

  /// Construit un paiement à partir d'une ligne de base de données [map].
  factory Payment.fromMap(Map<String, Object?> map) => Payment(
    id: map['id'] as String,
    orderId: map['order_id'] as String,
    amount: map['amount'] as int,
    paidAt: DateTime.parse(map['paid_at'] as String),
    method: PaymentMethod.fromValue(map['method'] as String?),
    note: map['note'] as String?,
  );

  /// Convertit le paiement en map pour l'enregistrement en base de données.
  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'order_id': orderId,
    'amount': amount,
    'paid_at': paidAt.toIso8601String(),
    'method': method?.value,
    'note': note,
  };
}

/// Résumé financier calculé d'une commande (§4.6).
class OrderBalance {
  /// Crée un résumé financier.
  const OrderBalance({required this.totalPrice, required this.totalPaid});

  /// Prix total convenu pour la commande.
  final int totalPrice;

  /// Montant total déjà payé.
  final int totalPaid;

  /// Solde restant. Peut être négatif en cas de trop-perçu.
  int get remaining => totalPrice - totalPaid;

  /// Indique si les paiements dépassent le prix total.
  bool get isOverpaid => totalPaid > totalPrice;

  /// Indique si le montant payé couvre exactement le prix total.
  bool get isSettled => totalPaid == totalPrice;

  /// Montant du trop-perçu lorsqu'il existe.
  int get overpaidAmount => isOverpaid ? totalPaid - totalPrice : 0;
}
