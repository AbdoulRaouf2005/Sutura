/// Méthodes de paiement facultatives (§4.6).
enum PaymentMethod {
  cash('cash', 'Espèces'),
  transfer('transfer', 'Transfert'),
  other('other', 'Autre');

  const PaymentMethod(this.value, this.label);

  final String value;
  final String label;

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
  const Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.paidAt,
    this.method,
    this.note,
  });

  final String id;
  final String orderId;

  /// Montant versé, en FCFA (entier, strictement supérieur à zéro).
  final int amount;
  final DateTime paidAt;
  final PaymentMethod? method;
  final String? note;

  factory Payment.fromMap(Map<String, Object?> map) => Payment(
        id: map['id'] as String,
        orderId: map['order_id'] as String,
        amount: map['amount'] as int,
        paidAt: DateTime.parse(map['paid_at'] as String),
        method: PaymentMethod.fromValue(map['method'] as String?),
        note: map['note'] as String?,
      );

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
  const OrderBalance({required this.totalPrice, required this.totalPaid});

  final int totalPrice;
  final int totalPaid;

  /// Solde restant. Peut être négatif en cas de trop-perçu.
  int get remaining => totalPrice - totalPaid;

  /// Vrai si les paiements dépassent le prix total.
  bool get isOverpaid => totalPaid > totalPrice;

  /// Vrai si le montant payé couvre exactement le prix total.
  bool get isSettled => totalPaid == totalPrice;

  int get overpaidAmount => isOverpaid ? totalPaid - totalPrice : 0;
}
