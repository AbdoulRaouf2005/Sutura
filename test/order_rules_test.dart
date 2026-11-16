import 'package:flutter_test/flutter_test.dart';
import 'package:sutura/features/orders/models/order.dart';
import 'package:sutura/features/payments/models/payment.dart';

/// Fabrique une commande de test avec une date de livraison et un statut donnés.
Order _order({
  required DateTime deliveryAt,
  OrderStatus status = OrderStatus.inProgress,
}) => Order(
  id: 'o1',
  clientId: 'c1',
  totalPrice: 10000,
  deliveryAt: deliveryAt,
  status: status,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

void main() {
  /// Tests de la règle métier isLate selon la date et le statut.
  group('Order.isLate', () {
    // Date de référence utilisée comme "maintenant" dans tous les cas.
    final DateTime now = DateTime(2026, 6, 15);

    /// Une livraison passée sur une commande active est considérée en retard.
    test('vraie si la livraison est passée et la commande active', () {
      expect(
        _order(deliveryAt: DateTime(2026, 6, 10)).isLate(now: now),
        isTrue,
      );
    });

    /// Une livraison future ne peut pas être en retard.
    test('fausse si la livraison est future', () {
      expect(
        _order(deliveryAt: DateTime(2026, 6, 20)).isLate(now: now),
        isFalse,
      );
    });

    /// Une commande livrée n'est jamais en retard, même si la date est dépassée.
    test('fausse si la commande est livrée, même en retard', () {
      expect(
        _order(
          deliveryAt: DateTime(2026, 6, 10),
          status: OrderStatus.delivered,
        ).isLate(now: now),
        isFalse,
      );
    });

    /// Une commande annulée n'est jamais en retard, même si la date est dépassée.
    test('fausse si la commande est annulée, même en retard', () {
      expect(
        _order(
          deliveryAt: DateTime(2026, 6, 10),
          status: OrderStatus.cancelled,
        ).isLate(now: now),
        isFalse,
      );
    });
  });

  /// Tests du calcul de solde entre prix total et montant payé.
  group('OrderBalance', () {
    /// Vérifie le reste à payer et les drapeaux pour un paiement partiel.
    test('calcule le solde restant', () {
      const OrderBalance balance = OrderBalance(
        totalPrice: 10000,
        totalPaid: 4000,
      );
      expect(balance.remaining, 6000);
      expect(balance.isSettled, isFalse);
      expect(balance.isOverpaid, isFalse);
    });

    /// Un paiement égal au prix total solde la commande.
    test('signale un paiement complet', () {
      const OrderBalance balance = OrderBalance(
        totalPrice: 10000,
        totalPaid: 10000,
      );
      expect(balance.remaining, 0);
      expect(balance.isSettled, isTrue);
    });

    /// Un paiement supérieur au prix total est signalé sans masquer le montant.
    test('signale un trop-perçu sans le masquer', () {
      const OrderBalance balance = OrderBalance(
        totalPrice: 10000,
        totalPaid: 12000,
      );
      expect(balance.isOverpaid, isTrue);
      expect(balance.remaining, -2000);
      expect(balance.overpaidAmount, 2000);
    });
  });

  /// Tests de la conversion des statuts stockés en valeurs de l'énumération.
  group('OrderStatus', () {
    /// Vérifie qu'une valeur connue est convertie et qu'une valeur inconnue retombe sur toStart.
    test('convertit une valeur stockée en statut', () {
      expect(OrderStatus.fromValue('ready'), OrderStatus.ready);
      expect(OrderStatus.fromValue('inconnu'), OrderStatus.toStart);
    });
  });
}
