import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/state/data_controller.dart';
import '../../features/gallery/models/garment_model.dart';

/// Accès aux modèles de la galerie (table `garment_models`).
class GarmentModelRepository {
  GarmentModelRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<List<GarmentModel>> list({
    String query = '',
    String? category,
    bool includeArchived = false,
  }) async {
    final db = await _db.database;
    final List<String> clauses = <String>[];
    final List<Object?> args = <Object?>[];

    if (!includeArchived) clauses.add('is_archived = 0');

    final String trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      clauses.add('name LIKE ?');
      args.add('%$trimmed%');
    }
    if (category != null && category.isNotEmpty) {
      clauses.add('category = ?');
      args.add(category);
    }

    final String? where = clauses.isEmpty ? null : clauses.join(' AND ');
    final List<Map<String, Object?>> rows = await db.query(
      'garment_models',
      where: where,
      whereArgs: args,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(GarmentModel.fromMap).toList();
  }

  Future<GarmentModel?> findById(String id) async {
    final db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      'garment_models',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : GarmentModel.fromMap(rows.first);
  }

  Future<void> insert(GarmentModel model) async {
    final db = await _db.database;
    await db.insert(
      'garment_models',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    DataController.instance.notify(DataEntity.models);
  }

  Future<void> update(GarmentModel model) async {
    final db = await _db.database;
    await db.update(
      'garment_models',
      model.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[model.id],
    );
    DataController.instance.notify(DataEntity.models);
  }

  Future<int> countActive() async {
    final db = await _db.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM garment_models WHERE is_archived = 0',
    );
    return (rows.first['n'] as int?) ?? 0;
  }
}
