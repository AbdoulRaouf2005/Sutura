import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/state/data_controller.dart';
import '../../features/payments/models/payment.dart';

/// Accès aux paiements (table `payments`).
class PaymentRepository {
  PaymentRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  /// Versements d'une commande, du plus récent au plus ancien.
  Future<List<Payment>> listForOrder(String orderId) async {
    final db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      'payments',
      where: 'order_id = ?',
      whereArgs: <Object?>[orderId],
      orderBy: 'paid_at DESC',
    );
    return rows.map(Payment.fromMap).toList();
  }

  Future<void> insert(Payment payment) async {
    final db = await _db.database;
    await db.insert(
      'payments',
      payment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    DataController.instance.notify(DataEntity.payments);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('payments', where: 'id = ?', whereArgs: <Object?>[id]);
    DataController.instance.notify(DataEntity.payments);
  }

  /// Somme des paiements d'une commande.
  Future<int> totalPaidForOrder(String orderId) async {
    final db = await _db.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM payments WHERE order_id = ?',
      <Object?>[orderId],
    );
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  /// Total restant à encaisser sur les commandes actives (§4.1).
  Future<int> totalOutstanding() async {
    final db = await _db.database;
    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT COALESCE(SUM(o.total_price), 0) AS price,
             COALESCE((
               SELECT SUM(p.amount) FROM payments p
               JOIN orders o2 ON o2.id = p.order_id
               WHERE o2.status NOT IN ('delivered', 'cancelled')
             ), 0) AS paid
      FROM orders o
      WHERE o.status NOT IN ('delivered', 'cancelled')
    ''');
    final int price = (rows.first['price'] as num?)?.toInt() ?? 0;
    final int paid = (rows.first['paid'] as num?)?.toInt() ?? 0;
    final int remaining = price - paid;
    return remaining < 0 ? 0 : remaining;
  }
}
