import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_migrations.dart';

/// Point d'accès unique à la base SQLite locale de Sutura.
///
/// Toutes les opérations de données passent par `AppDatabase.instance.database`.
class AppDatabase {
  /// Constructeur privé pour le singleton.
  AppDatabase._();

  /// Instance unique d'accès à la base de données.
  static final AppDatabase instance = AppDatabase._();

  /// Nom du fichier de base de données SQLite.
  static const String _fileName = 'sutura.db';

  /// Référence à la base ouverte, mise en cache.
  Database? _db;

  /// Ouvre la base si nécessaire puis la retourne.
  ///
  /// Retourne l'instance [Database] prête à l'emploi.
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  /// Ouvre ou crée le fichier de base de données SQLite.
  ///
  /// Retourne la base configurée avec les migrations et les clés étrangères.
  Future<Database> _open() async {
    final String path = p.join(await getDatabasesPath(), _fileName);
    return openDatabase(
      path,
      version: DatabaseMigrations.schemaVersion,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crée le schéma initial de la base lors de sa première ouverture.
  ///
  /// [db] est la base à initialiser et [version] la version cible du schéma.
  Future<void> _onCreate(Database db, int version) async {
    final Batch batch = db.batch();
    for (final List<String> statements in DatabaseMigrations.byVersion.values) {
      for (final String statement in statements) {
        batch.execute(statement);
      }
    }
    await batch.commit(noResult: true);
  }

  /// Applique les migrations nécessaires lors d'une mise à jour de version.
  ///
  /// [db] est la base, [oldVersion] la version actuelle et [newVersion] la cible.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      final List<String>? statements = DatabaseMigrations.byVersion[version];
      if (statements == null) continue;
      for (final String statement in statements) {
        await db.execute(statement);
      }
    }
  }

  /// Ferme la base (utilisé notamment par les tests).
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
