import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_migrations.dart';

/// Point d'accès unique à la base SQLite locale de Sutura.
///
/// Toutes les opérations de données passent par `AppDatabase.instance.database`.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _fileName = 'sutura.db';

  Database? _db;

  /// Ouvre la base si nécessaire puis la retourne.
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

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

  Future<void> _onCreate(Database db, int version) async {
    final Batch batch = db.batch();
    for (final List<String> statements
        in DatabaseMigrations.byVersion.values) {
      for (final String statement in statements) {
        batch.execute(statement);
      }
    }
    await batch.commit(noResult: true);
  }

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
