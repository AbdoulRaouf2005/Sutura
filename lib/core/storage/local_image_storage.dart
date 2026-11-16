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
  /// Crée le service de stockage avec un sélecteur d'images optionnel [picker].
  LocalImageStorage({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Sélecteur d'images utilisé pour capturer ou choisir une photo.
  final ImagePicker _picker;

  /// Nom du dossier de stockage des images dans les documents de l'application.
  static const String _folder = 'garment_images';

  /// Largeur maximale appliquée lors du redimensionnement.
  static const double _maxWidth = 1200;

  /// Hauteur maximale appliquée lors du redimensionnement.
  static const double _maxHeight = 1600;

  /// Qualité de compression JPEG appliquée lors de l'enregistrement.
  static const int _quality = 80;

  /// Prend une photo avec l'appareil photo puis la copie en local.
  ///
  /// Retourne le chemin du fichier enregistré ou `null` si annulé.
  Future<String?> pickFromCamera() => _pickAndStore(ImageSource.camera);

  /// Choisit une image existante depuis la galerie puis la copie en local.
  ///
  /// Retourne le chemin du fichier enregistré ou `null` si annulé.
  Future<String?> pickFromGallery() => _pickAndStore(ImageSource.gallery);

  /// Sélectionne une image depuis la [source] donnée, la copie localement et
  /// retourne son chemin, ou `null` si la sélection est annulée.
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

  /// S'assure que le répertoire de stockage des images existe et le retourne.
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
