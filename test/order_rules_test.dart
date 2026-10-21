import 'package:flutter_test/flutter_test.dart';
import 'package:sutura/features/orders/models/order.dart';
import 'package:sutura/features/payments/models/payment.dart';

Order _order({
  required DateTime deliveryAt,
  OrderStatus status = OrderStatus.inProgress,
}) =>
    Order(
      id: 'o1',
      clientId: 'c1',
      totalPrice: 10000,
      deliveryAt: deliveryAt,
      status: status,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('Order.isLate', () {
    final DateTime now = DateTime(2026, 6, 15);

    test('vraie si la livraison est passée et la commande active', () {
      expect(
        _order(deliveryAt: DateTime(2026, 6, 10)).isLate(now: now),
        isTrue,
      );
    });

    test('fausse si la livraison est future', () {
      expect(
        _order(deliveryAt: DateTime(2026, 6, 20)).isLate(now: now),
        isFalse,
      );
    });

    test('fausse si la commande est livrée, même en retard', () {
      expect(
        _order(
          deliveryAt: DateTime(2026, 6, 10),
          status: OrderStatus.delivered,
        ).isLate(now: now),
        isFalse,
      );
    });

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

  group('OrderBalance', () {
    test('calcule le solde restant', () {
      const OrderBalance balance =
          OrderBalance(totalPrice: 10000, totalPaid: 4000);
      expect(balance.remaining, 6000);
      expect(balance.isSettled, isFalse);
      expect(balance.isOverpaid, isFalse);
    });

    test('signale un paiement complet', () {
      const OrderBalance balance =
          OrderBalance(totalPrice: 10000, totalPaid: 10000);
      expect(balance.remaining, 0);
      expect(balance.isSettled, isTrue);
    });

    test('signale un trop-perçu sans le masquer', () {
      const OrderBalance balance =
          OrderBalance(totalPrice: 10000, totalPaid: 12000);
      expect(balance.isOverpaid, isTrue);
      expect(balance.remaining, -2000);
      expect(balance.overpaidAmount, 2000);
    });
  });

  group('OrderStatus', () {
    test('convertit une valeur stockée en statut', () {
      expect(OrderStatus.fromValue('ready'), OrderStatus.ready);
      expect(OrderStatus.fromValue('inconnu'), OrderStatus.toStart);
    });
  });
}
