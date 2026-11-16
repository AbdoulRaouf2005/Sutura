import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../state/data_controller.dart';

/// Résultat d'une opération de sauvegarde ou de restauration.
enum BackupResult {
  /// L'opération s'est terminée avec succès.
  success,

  /// L'opération a été annulée par l'utilisateur.
  cancelled,

  /// L'opération a échoué.
  failed,
}

/// Sauvegarde et restauration de la base SQLite et des photos locales.
///
/// Format du zip :
/// - `sutura.db` (base de données)
/// - `garment_images/` (répertoire des photos copiées)
class BackupService {
  /// Constructeur privé pour le singleton.
  BackupService._();

  /// Instance unique du service de sauvegarde.
  static final BackupService instance = BackupService._();

  /// Nom du fichier de base dans l'archive.
  static const String _dbFileName = 'sutura.db';

  /// Nom du dossier contenant les images dans l'archive.
  static const String _imagesFolder = 'garment_images';

  /// En-tête binaire caractéristique d'un fichier SQLite valide.
  static const List<int> _sqliteHeader = <int>[
    0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, // "SQLite"
    0x20, 0x66, 0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00, // " format 3\0"
  ];

  /// Exporte la base et les images dans un fichier zip.
  ///
  /// Retourne le chemin du fichier créé, ou `null` en cas d'échec.
  Future<String?> exportBackup() async {
    try {
      final Database db = await AppDatabase.instance.database;

      // Force l'écriture des transactions en attente dans le fichier principal.
      // `rawQuery` est utilisé car un PRAGMA renvoie des lignes et échoue avec
      // `execute` (execSQL) sur Android.
      try {
        await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
      } catch (error) {
        debugPrint('Checkpoint WAL impossible (ignoré) : $error');
      }

      final File dbFile = File(db.path);
      if (!await dbFile.exists()) {
        throw StateError('Fichier de base introuvable : ${db.path}');
      }

      final Uint8List dbBytes = await dbFile.readAsBytes();
      if (!_isSqliteFile(dbBytes)) {
        throw StateError('Le fichier de base est invalide');
      }

      final Directory docs = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory(p.join(docs.path, _imagesFolder));

      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateFormat('yyyyMMdd_HHmmss')
          .format(DateTime.now());
      final String zipName = 'sutura_backup_$timestamp.zip';
      final String zipPath = p.join(tempDir.path, zipName);

      final Archive archive = Archive();
      archive.addFile(ArchiveFile(_dbFileName, dbBytes.length, dbBytes));

      if (await imagesDir.exists()) {
        await for (final FileSystemEntity entity in imagesDir.list()) {
          if (entity is File) {
            final String name = p.basename(entity.path);
            final Uint8List bytes = await entity.readAsBytes();
            archive.addFile(
              ArchiveFile(p.join(_imagesFolder, name), bytes.length, bytes),
            );
          }
        }
      }

      final List<int> zipBytes = ZipEncoder().encode(archive);
      await File(zipPath).writeAsBytes(zipBytes, flush: true);

      return zipPath;
    } catch (error, stackTrace) {
      debugPrint('Échec de l\'export de sauvegarde : $error\n$stackTrace');
      return null;
    }
  }

  /// Partage le fichier de sauvegarde avec l'application de partage système.
  ///
  /// Retourne un [BackupResult] indiquant le succès, l'annulation ou l'échec.
  Future<BackupResult> shareBackup() async {
    final String? zipPath = await exportBackup();
    if (zipPath == null) return BackupResult.failed;
    try {
      final XFile file = XFile(zipPath, mimeType: 'application/zip');
      final ShareResult result = await Share.shareXFiles(<XFile>[
        file,
      ], subject: 'Sauvegarde Sutura');
      if (result.status == ShareResultStatus.dismissed) {
        return BackupResult.cancelled;
      }
      return BackupResult.success;
    } catch (error, stackTrace) {
      debugPrint('Échec du partage de sauvegarde : $error\n$stackTrace');
      return BackupResult.failed;
    }
  }

  /// Restaure la base et les images depuis un fichier zip sélectionné.
  ///
  /// Le contenu du zip est validé avant de toucher aux données actuelles. En
  /// cas d'échec pendant le remplacement, les données précédentes sont
  /// restaurées à partir d'une copie de secours.
  /// Retourne un [BackupResult] indiquant le résultat de l'opération.
  Future<BackupResult> restoreFromPicker() async {
    FilePickerResult? picked;
    try {
      // `FileType.any` plutôt que `FileType.custom` : sur Android, le filtre
      // par extension MIME masque souvent les fichiers .zip exportés par
      // l'application. La validité du fichier est vérifiée plus bas.
      picked = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
    } catch (error, stackTrace) {
      debugPrint('Échec du sélecteur de fichier : $error\n$stackTrace');
      return BackupResult.failed;
    }
    if (picked == null || picked.files.isEmpty) {
      return BackupResult.cancelled;
    }

    final String? sourcePath = picked.files.single.path;
    if (sourcePath == null) {
      debugPrint('Restauration impossible : chemin du fichier indisponible');
      return BackupResult.failed;
    }

    // Lit et valide l'archive AVANT de supprimer les données actuelles.
    Uint8List? newDbBytes;
    final Map<String, Uint8List> restoredImages = <String, Uint8List>{};
    try {
      final List<int> zipBytes = await File(sourcePath).readAsBytes();
      final Archive archive = ZipDecoder().decodeBytes(zipBytes);
      for (final ArchiveFile file in archive) {
        if (!file.isFile) continue;
        final String name = file.name.replaceAll('\\', '/');
        final List<int> data = file.content as List<int>;
        if (name == _dbFileName || name.endsWith('/$_dbFileName')) {
          newDbBytes = Uint8List.fromList(data);
        } else if (name.startsWith('$_imagesFolder/') && !name.endsWith('/')) {
          final String imageName = p.basename(name);
          if (imageName.isNotEmpty) {
            restoredImages[imageName] = Uint8List.fromList(data);
          }
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Archive de sauvegarde illisible : $error\n$stackTrace');
      return BackupResult.failed;
    }

    if (newDbBytes == null || !_isSqliteFile(newDbBytes)) {
      debugPrint('L\'archive ne contient pas de base SQLite valide');
      return BackupResult.failed;
    }

    final Directory docs = await getApplicationDocumentsDirectory();
    final Directory imagesDir = Directory(p.join(docs.path, _imagesFolder));
    final Database current = await AppDatabase.instance.database;
    final File dbFile = File(current.path);
    await AppDatabase.instance.close();

    final Directory tempDir = await getTemporaryDirectory();
    final String timestamp = DateFormat('yyyyMMdd_HHmmss')
        .format(DateTime.now());
    final Directory safetyDir = Directory(
      p.join(tempDir.path, 'sutura_restore_$timestamp'),
    );

    bool dbBackedUp = false;
    bool imagesBackedUp = false;

    try {
      await safetyDir.create(recursive: true);
      if (await dbFile.exists()) {
        await dbFile.copy(p.join(safetyDir.path, _dbFileName));
        dbBackedUp = true;
      }
      if (await imagesDir.exists()) {
        await _copyDirectory(
          imagesDir,
          Directory(p.join(safetyDir.path, _imagesFolder)),
        );
        imagesBackedUp = true;
      }

      await _deleteDatabaseFiles(dbFile.path);
      await dbFile.writeAsBytes(newDbBytes, flush: true);

      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }
      await imagesDir.create(recursive: true);
      for (final MapEntry<String, Uint8List> entry in restoredImages.entries) {
        await File(p.join(imagesDir.path, entry.key))
            .writeAsBytes(entry.value, flush: true);
      }

      final Database db = await AppDatabase.instance.database;
      final List<Map<String, Object?>> check = await db.rawQuery(
        "SELECT COUNT(*) AS n FROM sqlite_master WHERE type = 'table'",
      );
      if (((check.first['n'] as int?) ?? 0) == 0) {
        throw StateError('La base restaurée ne contient aucune table');
      }

      DataController.instance.notifyAll();
      await _tryDeleteDirectory(safetyDir);
      return BackupResult.success;
    } catch (error, stackTrace) {
      debugPrint('Échec de la restauration : $error\n$stackTrace');
      await _rollback(
        dbFile: dbFile,
        imagesDir: imagesDir,
        safetyDir: safetyDir,
        dbBackedUp: dbBackedUp,
        imagesBackedUp: imagesBackedUp,
      );
      return BackupResult.failed;
    }
  }

  /// Restaure les données précédentes à partir de la copie de secours.
  ///
  /// Utilisé en cas d'échec pendant le processus de restauration.
  Future<void> _rollback({
    required File dbFile,
    required Directory imagesDir,
    required Directory safetyDir,
    required bool dbBackedUp,
    required bool imagesBackedUp,
  }) async {
    try {
      await AppDatabase.instance.close();
      await _deleteDatabaseFiles(dbFile.path);
      if (dbBackedUp) {
        await File(p.join(safetyDir.path, _dbFileName)).copy(dbFile.path);
      }
      if (imagesBackedUp) {
        if (await imagesDir.exists()) {
          await imagesDir.delete(recursive: true);
        }
        await _copyDirectory(
          Directory(p.join(safetyDir.path, _imagesFolder)),
          imagesDir,
        );
      }
      await AppDatabase.instance.database;
      DataController.instance.notifyAll();
    } catch (error, stackTrace) {
      debugPrint('Échec du retour arrière : $error\n$stackTrace');
      try {
        await AppDatabase.instance.database;
      } catch (_) {}
    } finally {
      await _tryDeleteDirectory(safetyDir);
    }
  }

  /// Supprime le fichier de base de données et ses fichiers auxiliaires WAL/SHM/journal.
  Future<void> _deleteDatabaseFiles(String dbPath) async {
    for (final String suffix in <String>['', '-wal', '-shm', '-journal']) {
      final File file = File('$dbPath$suffix');
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  /// Copie les fichiers d'un répertoire [source] vers [destination].
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final FileSystemEntity entity in source.list()) {
      if (entity is File) {
        await entity.copy(p.join(destination.path, p.basename(entity.path)));
      }
    }
  }

  /// Tente de supprimer un répertoire [dir] sans lever d'exception en cas d'échec.
  Future<void> _tryDeleteDirectory(Directory dir) async {
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  /// Vérifie si les [bytes] correspondent à l'en-tête d'un fichier SQLite valide.
  bool _isSqliteFile(List<int> bytes) {
    if (bytes.length < _sqliteHeader.length) return false;
    for (int i = 0; i < _sqliteHeader.length; i++) {
      if (bytes[i] != _sqliteHeader[i]) return false;
    }
    return true;
  }
}
