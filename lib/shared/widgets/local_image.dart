import 'dart:io';

import 'package:flutter/material.dart';

/// Affiche une photo locale avec une gestion propre des cas d'erreur :
/// fichier manquant, invalide, ou vide (§11).
class LocalImage extends StatelessWidget {
  /// Crée une image locale.
  ///
  /// [path] est le chemin du fichier ; [fit] contrôle le cadrage et [label]
  /// le texte accessible. [cacheWidth] peut réduire la mémoire de décodage.
  const LocalImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.label,
    this.cacheWidth,
  });

  /// Chemin local du fichier image ; `null` ou vide affiche un espace réservé.
  final String? path;

  /// Mode d'ajustement de l'image dans son espace.
  final BoxFit fit;

  /// Texte alternatif/accessible pour l'image (guide §11).
  final String? label;

  /// Largeur de décodage en pixels. Réduit la mémoire utilisée pour les
  /// vignettes d'une grille tout en gardant l'image nette.
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    // Aucun chemin fourni : affiche directement l'espace réservé.
    if (path == null || path!.isEmpty) {
      return const _Placeholder(icon: Icons.image_outlined);
    }
    return Image.file(
      File(path!),
      fit: fit,
      semanticLabel: label,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      // Fichier manquant ou illisible : affiche une icône d'image cassée.
      errorBuilder: (_, _, _) =>
          const _Placeholder(icon: Icons.broken_image_outlined),
    );
  }
}

class _Placeholder extends StatelessWidget {
  /// Espace réservé affiché lorsqu'aucune image valide n'est disponible.
  const _Placeholder({required this.icon});

  /// Icône représentant l'état (image absente ou cassée).
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
      child: Center(
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface
              .withValues(alpha: 0.35),
          size: 32,
        ),
      ),
    );
  }
}
