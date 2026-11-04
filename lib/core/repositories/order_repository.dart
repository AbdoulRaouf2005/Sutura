import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/state/data_controller.dart';
import '../../features/orders/models/order.dart';

/// Accès aux commandes (table `orders`).
class OrderRepository {
  OrderRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<List<Order>> list({
    String? clientId,
    OrderStatus? status,
    bool onlyLate = false,
    bool onlyUpcoming = false,
  }) async {
    final db = await _db.database;
    final List<String> clauses = <String>[];
    final List<Object?> args = <Object?>[];
    final String nowIso = DateTime.now().toIso8601String();

    if (clientId != null) {
      clauses.add('client_id = ?');
      args.add(clientId);
    }
    if (status != null) {
      clauses.add('status = ?');
      args.add(status.value);
    }
    if (onlyLate) {
      clauses.add(
        "delivery_at < ? AND status NOT IN ('delivered', 'cancelled')",
      );
      args.add(nowIso);
    }
    if (onlyUpcoming) {
      clauses.add(
        "delivery_at >= ? AND status NOT IN ('delivered', 'cancelled')",
      );
      args.add(nowIso);
    }

    final String? where = clauses.isEmpty ? null : clauses.join(' AND ');
    final List<Map<String, Object?>> rows = await db.query(
      'orders',
      where: where,
      whereArgs: args,
      orderBy: 'delivery_at ASC',
    );
    return rows.map(Order.fromMap).toList();
  }

  Future<Order?> findById(String id) async {
    final db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : Order.fromMap(rows.first);
  }

  /// Commandes accompagnées du nom du client, en une seule requête.
  ///
  /// Évite une requête par commande, ce qui ralentissait nettement la liste
  /// dès que l'atelier avait quelques dizaines de commandes.
  Future<List<OrderWithClient>> listWithClientNames({
    String? clientId,
    OrderStatus? status,
    bool onlyLate = false,
    bool onlyUpcoming = false,
  }) async {
    final db = await _db.database;
    final List<String> clauses = <String>[];
    final List<Object?> args = <Object?>[];
    final String nowIso = DateTime.now().toIso8601String();

    if (clientId != null) {
      clauses.add('o.client_id = ?');
      args.add(clientId);
    }
    if (status != null) {
      clauses.add('o.status = ?');
      args.add(status.value);
    }
    if (onlyLate) {
      clauses.add(
        "o.delivery_at < ? AND o.status NOT IN ('delivered', 'cancelled')",
      );
      args.add(nowIso);
    }
    if (onlyUpcoming) {
      clauses.add(
        "o.delivery_at >= ? AND o.status NOT IN ('delivered', 'cancelled')",
      );
      args.add(nowIso);
    }

    final String where =
        clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '''
      SELECT o.*, c.full_name AS client_name
      FROM orders o
      LEFT JOIN clients c ON c.id = o.client_id
      $where
      ORDER BY o.delivery_at ASC
      ''',
      args,
    );
    return rows
        .map(
          (Map<String, Object?> row) => OrderWithClient(
            order: Order.fromMap(row),
            clientName: (row['client_name'] as String?) ?? 'Client inconnu',
          ),
        )
        .toList();
  }

  Future<void> insert(Order order) async {
    final db = await _db.database;
    await db.insert(
      'orders',
      order.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    DataController.instance.notify(DataEntity.orders);
  }

  Future<void> update(Order order) async {
    final db = await _db.database;
    await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[order.id],
    );
    DataController.instance.notify(DataEntity.orders);
  }

  /// Nombre de commandes actives (ni livrées ni annulées).
  Future<int> countActive() async {
    final db = await _db.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      "SELECT COUNT(*) AS n FROM orders "
      "WHERE status NOT IN ('delivered', 'cancelled')",
    );
    return (rows.first['n'] as int?) ?? 0;
  }

  /// Nombre de commandes en retard (calculé, §4.5).
  Future<int> countLate() async {
    final db = await _db.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      "SELECT COUNT(*) AS n FROM orders "
      "WHERE delivery_at < ? AND status NOT IN ('delivered', 'cancelled')",
      <Object?>[DateTime.now().toIso8601String()],
    );
    return (rows.first['n'] as int?) ?? 0;
  }

  /// Commandes à livrer dans les [days] prochains jours, non livrées/annulées.
  Future<List<Order>> upcomingWithin(int days) async {
    final db = await _db.database;
    final DateTime now = DateTime.now();
    final DateTime limit = now.add(Duration(days: days));
    final List<Map<String, Object?>> rows = await db.query(
      'orders',
      where:
          "delivery_at >= ? AND delivery_at <= ? AND status NOT IN ('delivered', 'cancelled')",
      whereArgs: <Object?>[
        now.toIso8601String(),
        limit.toIso8601String(),
      ],
      orderBy: 'delivery_at ASC',
    );
    return rows.map(Order.fromMap).toList();
  }
}
