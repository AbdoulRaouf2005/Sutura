import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/state/data_controller.dart';
import '../../features/measurements/models/measurement_set.dart';

/// Accès aux mensurations (tables `measurement_sets` et `measurements`).
class MeasurementRepository {
  MeasurementRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  /// Jeux de mensurations d'un client, du plus récent au plus ancien.
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

  /// Enregistre un jeu de mensurations et toutes ses mesures dans une
  /// transaction (cahier des charges §5).
  Future<void> insertSet(
    MeasurementSet set,
    List<Measurement> measurements,
  ) async {
    final db = await _db.database;
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

  Future<void> deleteSet(String setId) async {
    final db = await _db.database;
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
