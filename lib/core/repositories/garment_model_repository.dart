import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/state/data_controller.dart';
import '../../features/gallery/models/garment_model.dart';

/// Accès aux modèles de la galerie (table `garment_models`).
class GarmentModelRepository {
  /// Crée le dépôt avec une base optionnelle [db].
  GarmentModelRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  /// Instance de base de données utilisée pour les opérations.
  final AppDatabase _db;

  /// Liste les modèles de vêtements avec filtres optionnels.
  ///
  /// [query] filtre par nom, [category] par catégorie et [includeArchived]
  /// inclut les modèles archivés. Retourne la liste correspondante.
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

  /// Recherche un modèle par son identifiant [id].
  ///
  /// Retourne le modèle trouvé ou `null` s'il n'existe pas.
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

  /// Insère un nouveau [model] dans la base et notifie les écouteurs.
  Future<void> insert(GarmentModel model) async {
    final db = await _db.database;
    await db.insert(
      'garment_models',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    DataController.instance.notify(DataEntity.models);
  }

  /// Met à jour un [model] existant et notifie les écouteurs.
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

  /// Retourne le nombre de modèles actifs (non archivés).
  Future<int> countActive() async {
    final db = await _db.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM garment_models WHERE is_archived = 0',
    );
    return (rows.first['n'] as int?) ?? 0;
  }
}
