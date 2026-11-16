import 'package:flutter_test/flutter_test.dart';
import 'package:sutura/features/orders/models/order.dart';
import 'package:sutura/features/payments/models/payment.dart';

void main() {
  /// Tests des instantanés de commande liés au modèle et aux mesures.
  group('Order snapshot', () {
    /// Vérifie que les noms et chemins d'image sont figés dans la commande.
    test('conserve le nom du modèle même si le modèle change ensuite', () {
      // Commande contenant un modèle et un ensemble de mesures associés.
      final Order order = Order(
        id: 'o1',
        clientId: 'c1',
        garmentModelId: 'g1',
        modelNameSnapshot: 'Boubou brodé',
        modelImageSnapshotPath: '/data/g1.jpg',
        measurementSetId: 's1',
        totalPrice: 25000,
        deliveryAt: DateTime(2026, 7, 1),
        status: OrderStatus.toStart,
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      );

      // Reconstruit la commande à partir de sa représentation en map.
      final Order roundTrip = Order.fromMap(order.toMap());

      expect(roundTrip.modelNameSnapshot, 'Boubou brodé');
      expect(roundTrip.modelImageSnapshotPath, '/data/g1.jpg');
      expect(roundTrip.measurementSetId, 's1');
      expect(roundTrip.garmentModelId, 'g1');
    });

    /// Vérifie qu'une commande sans modèle ni mesures reste valide.
    test('peut exister sans modèle ni mensurations', () {
      final Order order = Order(
        id: 'o2',
        clientId: 'c1',
        totalPrice: 0,
        deliveryAt: DateTime(2026, 7, 1),
        status: OrderStatus.toStart,
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      );
      final Map<String, Object?> map = order.toMap();
      expect(map['garment_model_id'], isNull);
      expect(map['measurement_set_id'], isNull);
      expect(map['model_name_snapshot'], isNull);
      expect(Order.fromMap(map).totalPrice, 0);
    });

    /// Vérifie que copyWith clearModel détache le modèle et efface ses instantanés.
    test('copyWith clearModel retire le modèle et ses snapshots', () {
      final Order order = Order(
        id: 'o3',
        clientId: 'c1',
        garmentModelId: 'g1',
        modelNameSnapshot: 'Robe',
        totalPrice: 10000,
        deliveryAt: DateTime(2026, 7, 1),
        status: OrderStatus.toStart,
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      );
      final Order cleared = order.copyWith(clearModel: true);
      expect(cleared.garmentModelId, isNull);
      expect(cleared.modelNameSnapshot, isNull);
    });
  });

  /// Tests du modèle Payment : sérialisation et champs optionnels.
  group('Payment', () {
    /// Vérifie qu'un aller-retour toMap/fromMap conserve tous les champs.
    test('sérialise et désérialise sans perte', () {
      // Paiement complet servant de référence pour le round-trip.
      final Payment payment = Payment(
        id: 'p1',
        orderId: 'o1',
        amount: 5000,
        paidAt: DateTime(2026, 6, 10),
        method: PaymentMethod.cash,
        note: 'Acompte',
      );

      final Payment roundTrip = Payment.fromMap(payment.toMap());

      expect(roundTrip.id, payment.id);
      expect(roundTrip.orderId, payment.orderId);
      expect(roundTrip.amount, 5000);
      expect(roundTrip.paidAt, payment.paidAt);
      expect(roundTrip.method, PaymentMethod.cash);
      expect(roundTrip.note, 'Acompte');
    });

    /// Vérifie qu'une méthode de paiement absente reste null après sérialisation.
    test('gère une méthode absente', () {
      final Payment payment = Payment(
        id: 'p2',
        orderId: 'o1',
        amount: 1000,
        paidAt: DateTime(2026, 6, 10),
      );
      expect(Payment.fromMap(payment.toMap()).method, isNull);
    });
  });

  /// Vérifie la conversion des méthodes et le retour à null pour les valeurs inconnues.
  test('PaymentMethod.fromValue gère les valeurs inconnues', () {
    expect(PaymentMethod.fromValue('cash'), PaymentMethod.cash);
    expect(PaymentMethod.fromValue('transfer'), PaymentMethod.transfer);
    expect(PaymentMethod.fromValue(null), isNull);
    expect(PaymentMethod.fromValue('inconnu'), isNull);
  });
}
