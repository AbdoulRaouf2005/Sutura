import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/id_generator.dart';

/// Gère le stockage local des photos de modèles (§4.4).
///
/// Les images sont copiées dans le répertoire privé de l'application plutôt
/// que de conserver uniquement un chemin temporaire du sélecteur. Elles sont
/// redimensionnées et compressées pour ne pas remplir le téléphone.
class LocalImageStorage {
  LocalImageStorage({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const String _folder = 'garment_images';
  static const double _maxWidth = 1200;
  static const double _maxHeight = 1600;
  static const int _quality = 80;

  /// Prend une photo avec l'appareil photo puis la copie en local.
  Future<String?> pickFromCamera() => _pickAndStore(ImageSource.camera);

  /// Choisit une image existante puis la copie en local.
  Future<String?> pickFromGallery() => _pickAndStore(ImageSource.gallery);

  Future<String?> _pickAndStore(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: _maxWidth,
      maxHeight: _maxHeight,
      imageQuality: _quality,
    );
    if (picked == null) return null;

    final Directory dir = await _ensureDirectory();
    final String extension = p.extension(picked.path).isEmpty
        ? '.jpg'
        : p.extension(picked.path).toLowerCase();
    final String fileName = '${newId()}$extension';
    final String destination = p.join(dir.path, fileName);

    await File(picked.path).copy(destination);
    return destination;
  }

  Future<Directory> _ensureDirectory() async {
    final Directory base = await getApplicationDocumentsDirectory();
    final Directory dir = Directory(p.join(base.path, _folder));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Supprime un fichier image local s'il existe. Ne lève jamais d'exception
  /// bloquante pour ne pas faire échouer l'opération métier appelante.
  Future<void> deleteFile(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final File file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Ignoré volontairement : un fichier manquant n'est pas une erreur.
    }
  }

  /// Indique si une photo locale existe réellement sur le disque.
  Future<bool> fileExists(String? path) async {
    if (path == null || path.isEmpty) return false;
    return File(path).exists();
  }
}
