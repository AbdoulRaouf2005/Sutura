import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/state/data_controller.dart';
import '../../features/orders/models/order.dart';

/// Accès aux commandes (table `orders`).
class OrderRepository {
  /// Crée le dépôt avec une base optionnelle [db].
  OrderRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  /// Instance de base de données utilisée pour les opérations.
  final AppDatabase _db;

  /// Liste les commandes selon les filtres fournis.
  ///
  /// [clientId] limite à un client, [status] à un statut, [onlyLate] aux
  /// commandes en retard et [onlyUpcoming] aux commandes à venir.
  /// Retourne la liste triée par date de livraison.
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

  /// Recherche une commande par son identifiant [id].
  ///
  /// Retourne la commande trouvée ou `null` si elle n'existe pas.
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

  /// Retourne les commandes accompagnées du nom du client en une seule requête.
  ///
  /// Évite une requête par commande, ce qui ralentissait nettement la liste
  /// dès que l'atelier avait quelques dizaines de commandes.
  /// Les paramètres de filtre sont identiques à [list].
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

    final String where = clauses.isEmpty
        ? ''
        : 'WHERE ${clauses.join(' AND ')}';
    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT o.*, c.full_name AS client_name
      FROM orders o
      LEFT JOIN clients c ON c.id = o.client_id
      $where
      ORDER BY o.delivery_at ASC
      ''', args);
    return rows
        .map(
          (Map<String, Object?> row) => OrderWithClient(
            order: Order.fromMap(row),
            clientName: (row['client_name'] as String?) ?? 'Client inconnu',
          ),
        )
        .toList();
  }

  /// Insère une nouvelle [order] dans la base et notifie les écouteurs.
  Future<void> insert(Order order) async {
    final db = await _db.database;
    await db.insert(
      'orders',
      order.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    DataController.instance.notify(DataEntity.orders);
  }

  /// Met à jour une [order] existante et notifie les écouteurs.
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

  /// Retourne le nombre de commandes actives (ni livrées ni annulées).
  Future<int> countActive() async {
    final db = await _db.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      "SELECT COUNT(*) AS n FROM orders "
      "WHERE status NOT IN ('delivered', 'cancelled')",
    );
    return (rows.first['n'] as int?) ?? 0;
  }

  /// Retourne le nombre de commandes en retard (calculé, §4.5).
  Future<int> countLate() async {
    final db = await _db.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      "SELECT COUNT(*) AS n FROM orders "
      "WHERE delivery_at < ? AND status NOT IN ('delivered', 'cancelled')",
      <Object?>[DateTime.now().toIso8601String()],
    );
    return (rows.first['n'] as int?) ?? 0;
  }

  /// Retourne les commandes à livrer dans les [days] prochains jours,
  /// non livrées et non annulées.
  Future<List<Order>> upcomingWithin(int days) async {
    final db = await _db.database;
    final DateTime now = DateTime.now();
    final DateTime limit = now.add(Duration(days: days));
    final List<Map<String, Object?>> rows = await db.query(
      'orders',
      where: "delivery_at >= ? AND delivery_at <= ? AND status NOT IN ('delivered', 'cancelled')",
      whereArgs: <Object?>[now.toIso8601String(), limit.toIso8601String()],
      orderBy: 'delivery_at ASC',
    );
    return rows.map(Order.fromMap).toList();
  }
}
