import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/state/data_controller.dart';
import '../../features/clients/models/client.dart';

/// Accès aux données des clients (table `clients`).
class ClientRepository {
  /// Crée le dépôt avec une base optionnelle [db] (utile pour les tests).
  ClientRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  /// Instance de base de données utilisée pour les opérations.
  final AppDatabase _db;

  /// Liste les clients, archives incluses ou non, avec recherche optionnelle
  /// par nom ou téléphone.
  ///
  /// [query] filtre sur le nom ou le téléphone, [includeArchived] inclut les
  /// archives si vrai. Retourne la liste des clients correspondants.
  Future<List<Client>> list({
    String query = '',
    bool includeArchived = false,
  }) async {
    final db = await _db.database;
    final List<String> clauses = <String>[];
    final List<Object?> args = <Object?>[];

    if (!includeArchived) clauses.add('is_archived = 0');

    final String trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      clauses.add('(full_name LIKE ? OR phone LIKE ?)');
      args
        ..add('%$trimmed%')
        ..add('%$trimmed%');
    }

    final String? where = clauses.isEmpty ? null : clauses.join(' AND ');
    final List<Map<String, Object?>> rows = await db.query(
      'clients',
      where: where,
      whereArgs: args,
      orderBy: 'full_name COLLATE NOCASE ASC',
    );
    return rows.map(Client.fromMap).toList();
  }

  /// Recherche un client par son identifiant [id].
  ///
  /// Retourne le client trouvé ou `null` s'il n'existe pas.
  Future<Client?> findById(String id) async {
    final db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      'clients',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : Client.fromMap(rows.first);
  }

  /// Insère un nouveau [client] dans la base et notifie les écouteurs.
  Future<void> insert(Client client) async {
    final db = await _db.database;
    await db.insert(
      'clients',
      client.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    DataController.instance.notify(DataEntity.clients);
  }

  /// Met à jour les informations d'un [client] existant et notifie les écouteurs.
  Future<void> update(Client client) async {
    final db = await _db.database;
    await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[client.id],
    );
    DataController.instance.notify(DataEntity.clients);
  }

  /// Retourne le nombre total de clients actifs (non archivés).
  Future<int> countActive() async {
    final db = await _db.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM clients WHERE is_archived = 0',
    );
    return (rows.first['n'] as int?) ?? 0;
  }
}
