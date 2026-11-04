import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../state/data_controller.dart';

/// Sauvegarde et restauration de la base SQLite et des photos locales.
///
/// Format du zip :
/// - `sutura.db` (base de données)
/// - `garment_images/` (répertoire des photos copiées)
class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  static const String _dbFileName = 'sutura.db';
  static const String _imagesFolder = 'garment_images';

  /// Exporte la base et les images dans un fichier zip.
  /// Retourne le chemin du fichier créé, ou `null` en cas d'échec.
  Future<String?> exportBackup() async {
    try {
      final Database db = await AppDatabase.instance.database;
      // S'assure que toutes les écritures en attente sont flushées.
      await db.execute('PRAGMA wal_checkpoint(TRUNCATE)');

      final String dbPath = p.join(await getDatabasesPath(), _dbFileName);
      final File dbFile = File(dbPath);
      if (!await dbFile.exists()) throw StateError('Base introuvable');

      final Directory docs = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory(p.join(docs.path, _imagesFolder));

      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String zipName = 'sutura_backup_$timestamp.zip';
      final String zipPath = p.join(tempDir.path, zipName);

      final Archive archive = Archive();

      // Ajoute la base
      final List<int> dbBytes = await dbFile.readAsBytes();
      archive.addFile(
        ArchiveFile(_dbFileName, dbBytes.length, dbBytes),
      );

      // Ajoute les images si elles existent
      if (await imagesDir.exists()) {
        await for (final FileSystemEntity entity in imagesDir.list()) {
          if (entity is File) {
            final String name = p.basename(entity.path);
            final List<int> bytes = await entity.readAsBytes();
            archive.addFile(
              ArchiveFile(p.join(_imagesFolder, name), bytes.length, bytes),
            );
          }
        }
      }

      final List<int> zipBytes = ZipEncoder().encode(archive);
      final File zipFile = File(zipPath);
      await zipFile.writeAsBytes(zipBytes);

      return zipPath;
    } catch (_) {
      return null;
    }
  }

  /// Partage le fichier de sauvegarde avec l'application de partage système.
  Future<bool> shareBackup() async {
    final String? zipPath = await exportBackup();
    if (zipPath == null) return false;
    try {
      final XFile file = XFile(zipPath, mimeType: 'application/zip');
      final ShareResult result = await Share.shareXFiles(
        <XFile>[file],
        subject: 'Sauvegarde Sutura',
      );
      return result.status == ShareResultStatus.success;
    } catch (_) {
      return false;
    }
  }

  /// Restaure la base et les images depuis un fichier zip sélectionné.
  /// Ferme la base avant de remplacer les fichiers. À utiliser avec
  /// précaution : cette opération remplace les données actuelles.
  Future<bool> restoreFromPicker() async {
    try {
      final FilePickerResult? picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['zip'],
        allowMultiple: false,
      );
      if (picked == null || picked.files.isEmpty) return false;

      final String? sourcePath = picked.files.single.path;
      if (sourcePath == null) return false;

      // Ferme la connexion SQLite avant de remplacer le fichier.
      await AppDatabase.instance.close();

      final Directory docs = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory(p.join(docs.path, _imagesFolder));
      final String dbPath = p.join(await getDatabasesPath(), _dbFileName);

      // Décompresse
      final List<int> zipBytes = await File(sourcePath).readAsBytes();
      final Archive archive = ZipDecoder().decodeBytes(zipBytes);

      // Supprime le dossier images existant
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }
      await imagesDir.create(recursive: true);

      // Supprime l'ancienne base
      final File oldDb = File(dbPath);
      if (await oldDb.exists()) {
        await oldDb.delete();
      }
      // Supprime aussi les journaux WAL/SHM s'ils existent
      for (final String suffix in <String>['-wal', '-shm']) {
        final File journal = File('$dbPath$suffix');
        if (await journal.exists()) await journal.delete();
      }

      bool dbRestored = false;
      for (final ArchiveFile file in archive) {
        if (file.isFile) {
          final String filename = file.name.replaceAll('\\', '/');
          final List<int> data = file.content as List<int>;

          if (filename == _dbFileName || filename.endsWith('/$_dbFileName')) {
            final File outFile = File(dbPath);
            await outFile.writeAsBytes(data);
            dbRestored = true;
          } else if (filename.startsWith('$_imagesFolder/')) {
            final String imageName = p.basename(filename);
            if (imageName.isNotEmpty) {
              final File outFile = File(p.join(imagesDir.path, imageName));
              await outFile.writeAsBytes(data);
            }
          }
        }
      }

      // Rouvre la base
      await AppDatabase.instance.database;
      // Les écrans affichent des données périmées : on les rafraîchit tous.
      DataController.instance.notifyAll();
      return dbRestored;
    } catch (_) {
      // Tente de rouvrir la base même en cas d'erreur partielle
      try {
        await AppDatabase.instance.database;
      } catch (_) {}
      return false;
    }
  }
}
