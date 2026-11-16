import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/state/data_controller.dart';
import '../../features/measurements/models/measurement_set.dart';

/// Accès aux mensurations (tables `measurement_sets` et `measurements`).
class MeasurementRepository {
  /// Crée le dépôt avec une base optionnelle [db].
  MeasurementRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  /// Instance de base de données utilisée pour les opérations.
  final AppDatabase _db;

  /// Retourne les jeux de mensurations d'un client [clientId], du plus récent au plus ancien.
  Future<List<MeasurementSet>> listSetsForClient(String clientId) async {
    final db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      'measurement_sets',
      where: 'client_id = ?',
      whereArgs: <Object?>[clientId],
      orderBy: 'measured_at DESC',
    );
    return rows.map(MeasurementSet.fromMap).toList();
  }

  /// Recherche un jeu de mensurations par son identifiant [id].
  ///
  /// Retourne le jeu trouvé ou `null` s'il n'existe pas.
  Future<MeasurementSet?> findSetById(String id) async {
    final db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      'measurement_sets',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : MeasurementSet.fromMap(rows.first);
  }

  /// Liste les mesures individuelles appartenant au jeu [setId].
  Future<List<Measurement>> listMeasurements(String setId) async {
    final db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      'measurements',
      where: 'measurement_set_id = ?',
      whereArgs: <Object?>[setId],
      orderBy: 'rowid ASC',
    );
    return rows.map(Measurement.fromMap).toList();
  }

  /// Enregistre un jeu de mensurations [set] et ses [measurements] dans une
  /// transaction (cahier des charges §5), puis notifie les écouteurs.
  Future<void> insertSet(
    MeasurementSet set,
    List<Measurement> measurements,
  ) async {
    final db = await _db.database;
    // Insertion atomique du jeu et de ses mesures.
    await db.transaction((Transaction txn) async {
      await txn.insert(
        'measurement_sets',
        set.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      for (final Measurement m in measurements) {
        await txn.insert(
          'measurements',
          m.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    });
    DataController.instance.notify(DataEntity.measurements);
  }

  /// Supprime le jeu [setId] et toutes ses mesures dans une transaction.
  Future<void> deleteSet(String setId) async {
    final db = await _db.database;
    // Suppression atomique des mesures puis du jeu parent.
    await db.transaction((Transaction txn) async {
      await txn.delete(
        'measurements',
        where: 'measurement_set_id = ?',
        whereArgs: <Object?>[setId],
      );
      await txn.delete(
        'measurement_sets',
        where: 'id = ?',
        whereArgs: <Object?>[setId],
      );
    });
    DataController.instance.notify(DataEntity.measurements);
  }
}
